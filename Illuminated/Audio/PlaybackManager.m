//
//  PlaybackManager.m
//  Illuminated
//
//  Created by Alexandru Solomon on 22.01.2026.
//

#import "PlaybackManager.h"
#import "BookmarkResolver.h"
#import "CoreDataStore.h"
#import "Track.h"
#import "TrackQueue.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#pragma mark - Constants

NSString *const PlaybackManagerTrackDidChangeNotification = @"PlaybackManagerTrackDidChangeNotification";
NSString *const PlaybackManagerPlaybackStateDidChangeNotification =
    @"PlaybackManagerPlaybackStateDidChangeNotification";
NSString *const PlaybackManagerPlaybackProgressDidChangeNotification =
    @"PlaybackManagerPlaybackProgressDidChangeNotification";

static const NSTimeInterval kPreviousTrackThreshold = 3.0;
static const NSTimeInterval kProgressTimerInterval = 0.5;

#pragma mark - PlaybackManager

@interface PlaybackManager ()

@property(strong) AVAudioEngine *engine;
@property(strong) AVAudioPlayerNode *playerNode;
@property(strong) AVAudioFile *currentFile;

@property(strong, nonatomic) TrackQueue *queue;

@property(strong) NSTimer *progressTimer;
@property(readwrite) float volume;

@property(nonatomic) NSTimeInterval seekOffset;
@property(atomic, assign) NSInteger playbackGeneration;

@end

@implementation PlaybackManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
  static PlaybackManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ sharedInstance = [[self alloc] init]; });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _queue = [[TrackQueue alloc] init];

    _engine = [[AVAudioEngine alloc] init];
    _playerNode = [[AVAudioPlayerNode alloc] init];
    _seekOffset = 0;
    _playbackGeneration = 0;

    [_engine attachNode:_playerNode];
    [_engine connect:_playerNode to:_engine.mainMixerNode format:nil];

    NSError *error;
    if (![_engine startAndReturnError:&error]) {
      NSLog(@"Engine failed to start: %@", error);
    }
  }
  return self;
}

#pragma mark - Public API

- (void)setVolume:(float)volume {
  _volume = MAX(0.0f, MIN(1.0f, volume));
  self.playerNode.volume = _volume;
}

- (BOOL)isPlaying {
  return self.playerNode.isPlaying;
}

- (Track *)currentTrack {
  return self.queue.currentTrack;
}

- (void)updateQueue:(NSArray<Track *> *)tracks {
  [self.queue setTracks:tracks];
}

- (NSURL *)currentPlaybackURL {
  return self.currentFile.url;
}

#pragma mark - Playback

- (void)playTrack:(Track *)track {
  NSParameterAssert(track);

  NSError *error;
  NSURL *url = [BookmarkResolver resolveAndAccessBookmarkData:track.urlBookmark error:&error];
  if (error) {
    NSLog(@"PlaybackManager: Failed to resolve bookmark for track. Error: %@", error.localizedDescription);
    return;
  }

  if (self.currentFile) {
    [BookmarkResolver releaseAccessedURL:self.currentFile.url];
  }

  AVAudioFile *newFile = [[AVAudioFile alloc] initForReading:url error:&error];
  if (!newFile) {
    NSLog(@"PlaybackManager: Error loading track with url: %@. Error: %@", url, error);
    return;
  }

  self.playbackGeneration++;
  [self.playerNode stop];

  self.currentFile = newFile;
  self.seekOffset = 0;

  [self.engine connect:self.playerNode to:self.engine.mainMixerNode format:self.currentFile.processingFormat];

  if (!self.engine.isRunning) {
    NSError *startError;
    if (![self.engine startAndReturnError:&startError]) {
      NSLog(@"Failed to start engine: %@", startError);
      return;
    }
  }

  [self scheduleFileAndPlay];

  [self.queue setCurrentTrack:track];

  [self notifyProgressDidChange];
  [self notifyDidChangeTrack:track];
  [self startProgressTimer];
  [[CoreDataStore writer] incrementPlayCountForTrack:track];
}

- (void)playNext {
  Track *nextTrack = [self.queue nextTrack];
  if (nextTrack) {
    [self playTrack:nextTrack];
  }
}

- (void)playPrevious {
  // If we are more than 3 secs into a song, "previous" is restart
  if ([self currentTime] > kPreviousTrackThreshold) {
    [self seekToTime:0];
    return;
  }

  Track *previousTrack = [self.queue previousTrack];
  if (previousTrack) {
    [self playTrack:previousTrack];
  }
}

- (void)togglePlayPause {
  if (self.isPlaying) {
    [self.playerNode pause];
    [self.progressTimer invalidate];
  } else {
    if (!self.playerNode.isPlaying) {
      [self.playerNode play];
    }
    [self startProgressTimer];
  }

  [self notifyPlaybackStateDidChange];
}

- (void)seekToTime:(NSTimeInterval)timeInterval {
  if (!self.currentFile) return;

  self.playbackGeneration++;

  BOOL wasPlaying = self.isPlaying;
  [self.playerNode stop];

  self.seekOffset = timeInterval;

  AVAudioFramePosition startFrame = (AVAudioFramePosition)(timeInterval * self.currentFile.processingFormat.sampleRate);
  AVAudioFrameCount frameCount = (AVAudioFrameCount)(self.currentFile.length - startFrame);

  if (frameCount > 0) {
    NSInteger currentGeneration = self.playbackGeneration;
    __weak typeof(self) weakSelf = self;

    // clang-format off
    [self.playerNode scheduleSegment:self.currentFile startingFrame:startFrame frameCount:frameCount atTime:nil completionHandler:^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) return;
      
      dispatch_async(dispatch_get_main_queue(), ^{
        if (strongSelf.playbackGeneration != currentGeneration) {
          return;
        }
        if (strongSelf.isPlaying) {
          [strongSelf playNext];
        }
      });
    }];
    // clang-format on
    if (wasPlaying) {
      [self.playerNode play];
    }
  }

  [self notifyProgressDidChange];
}

- (void)stop {
  [self.playerNode stop];
}

#pragma mark - Notifications

- (void)notifyProgressDidChange {
  [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerPlaybackProgressDidChangeNotification
                                                      object:nil];
}

- (void)notifyDidChangeTrack:(Track *)track {
  [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerTrackDidChangeNotification object:track];
}

- (void)notifyPlaybackStateDidChange {
  [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerPlaybackStateDidChangeNotification
                                                      object:nil];
}

#pragma mark - Private Methods

- (void)scheduleFileAndPlay {
  NSInteger currentGeneration = self.playbackGeneration;
  __weak typeof(self) weakSelf = self;

  // clang-format off
  [self.playerNode scheduleFile:self.currentFile atTime:nil completionHandler:^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if (strongSelf.playbackGeneration != currentGeneration) return;
      if (strongSelf.isPlaying) [strongSelf playNext];
    });
  }];
  // clang-format on

  [[self playerNode] setVolume:self.volume];
  [self.playerNode play];
}

- (NSTimeInterval)currentTime {
  if (self.seekOffset > 0 && !self.playerNode.isPlaying) {
    return self.seekOffset;
  }

  AVAudioTime *nodeTime = self.playerNode.lastRenderTime;
  if (!nodeTime) return self.seekOffset;

  AVAudioTime *playerTime = [self.playerNode playerTimeForNodeTime:nodeTime];
  if (!playerTime) return self.seekOffset;

  NSTimeInterval currentTime = (NSTimeInterval)playerTime.sampleTime / playerTime.sampleRate;
  return self.seekOffset + currentTime;
}

- (NSTimeInterval)duration {
  if (!self.currentFile) return 0;
  return (NSTimeInterval)self.currentFile.length / self.currentFile.processingFormat.sampleRate;
}

- (void)startProgressTimer {
  [self.progressTimer invalidate];
  // clang-format off
  self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *_) {
    [self notifyProgressDidChange];
  }];
  // clang-format on
}

@end
