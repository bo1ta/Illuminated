//
//  PlaybackManager.m
//  Illuminated
//
//  Created by Alexandru Solomon on 22.01.2026.
//
//

#import "TrackPlaybackController.h"
#import "Album.h"
#import "BookmarkResolver.h"
#import "Track+PlaybackItem.h"
#import "Track.h"
#import "TrackQueue.h"
#import "TrackService.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#pragma mark - Constants

NSString *const PlaybackManagerTrackDidChangeNotification = @"PlaybackManagerTrackDidChangeNotification";

static const NSTimeInterval kPreviousTrackThreshold = 3.0;
static const NSTimeInterval kProgressTimerInterval = 0.5;

#pragma mark - PlaybackManager

@interface TrackPlaybackController ()

@property(strong) AVAudioEngine *engine;
@property(strong) AVAudioPlayerNode *playerNode;
@property(strong) AVAudioFile *currentFile;
@property(strong, nullable) NSURL *currentSecurityScopeURL;

@property(strong, nonatomic) TrackQueue *queue;

@property(strong) NSTimer *progressTimer;

@property(nonatomic) NSTimeInterval seekOffset;
@property(atomic, assign) NSInteger playbackGeneration;

@property(nonatomic, copy) AudioBufferCallback audioBufferCallback;

@property(readwrite, assign, getter=isPlaying) BOOL isPlaying;

@end

@implementation TrackPlaybackController

#pragma mark - Singleton

+ (instancetype)sharedManager {
  static TrackPlaybackController *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ sharedInstance = [[self alloc] init]; });
  return sharedInstance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _repeatMode = RepeatModeOff;
    _queue = [[TrackQueue alloc] init];

    _engine = [[AVAudioEngine alloc] init];
    _playerNode = [[AVAudioPlayerNode alloc] init];
    _seekOffset = 0;
    _playbackGeneration = 0;
    _isPlaying = NO;

    [_engine attachNode:_playerNode];
    [_engine connect:_playerNode to:_engine.mainMixerNode format:nil];

    NSError *error;
    if (![_engine startAndReturnError:&error]) {
      NSLog(@"Engine failed to start: %@", error);
      return self;
    }
  }
  return self;
}

- (void)dealloc {
  [self.engine.mainMixerNode removeTapOnBus:0];

  if (self.currentSecurityScopeURL) {
    [self.currentSecurityScopeURL stopAccessingSecurityScopedResource];
  }
}

- (id<PlaybackItem>)currentItem {
  return self.queue.currentTrack;
}

#pragma mark - KVO

+ (NSSet<NSString *> *)keyPathsForValuesAffectingProgress {
  return [NSSet setWithObjects:@"currentTime", @"duration", @"currentTrack", @"currentArtworkPath", nil];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCurrentTrack {
  return [NSSet setWithObject:@"queue.currentTrack"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCurrentItem {
  return [NSSet setWithObject:@"queue.currentTrack"];
}

+ (NSSet *)keyPathsForValuesAffectingDuration {
  return [NSSet setWithObject:@"currentFile"];
}

- (double)progress {
  if (self.duration == 0) return 0.0;
  return self.currentTime / self.duration;
}

- (Track *)currentTrack {
  return self.queue.currentTrack;
}

- (NSString *)currentArtworkPath {
  return self.currentTrack.album.artworkPath;
}

#pragma mark - Public API

- (void)setVolume:(float)volume {
  _volume = MAX(0.0f, MIN(1.0f, volume));
  self.playerNode.volume = _volume;
}

- (void)updateQueue:(NSArray<Track *> *)tracks {
  [self.queue setTracks:tracks];
  [self didChangeValueForKey:@"currentTrack"];
}

- (NSURL *)currentPlaybackURL {
  return self.currentFile.url;
}

#pragma mark - Playback

- (void)playTrack:(Track *)track {
  NSParameterAssert(track);

  NSURL *securityScopeURL = nil;
  NSURL *url = [TrackService resolveTrackURL:track securityScopeURL:&securityScopeURL];
  if (!url) {
    [self.queue setCurrentTrack:track];
    [self playNext];
    return;
  }

  NSError *error = nil;
  AVAudioFile *newFile = [[AVAudioFile alloc] initForReading:url error:&error];
  if (!newFile) {
    NSLog(@"PlaybackManager: Error loading track with url: %@. Error: %@", url, error);
    if (securityScopeURL) {
      [securityScopeURL stopAccessingSecurityScopedResource];
    }
    return;
  }

  self.playbackGeneration++;
  [self.playerNode stop];

  if (self.currentSecurityScopeURL) {
    [self.currentSecurityScopeURL stopAccessingSecurityScopedResource];
  }

  self.currentFile = newFile;
  self.currentSecurityScopeURL = securityScopeURL;
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

  [self startProgressTimer];
  [self notifyDidChangeTrack:track];

  self.isPlaying = YES;
}

- (void)playNext {
  Track *nextTrack = [self.queue nextTrack];
  if (nextTrack) {
    [self playTrack:nextTrack];
  } else {
    self.isPlaying = NO;
    [self.progressTimer invalidate];
    if (self.currentSecurityScopeURL) {
      [self.currentSecurityScopeURL stopAccessingSecurityScopedResource];
      self.currentSecurityScopeURL = nil;
    }
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
    self.isPlaying = NO;
  } else {
    if (!self.playerNode.isPlaying) {
      [self.playerNode play];
    }
    [self startProgressTimer];
    self.isPlaying = YES;
  }
}

- (void)seekToTime:(NSTimeInterval)timeInterval {
  if (!self.currentFile) return;

  self.playbackGeneration++;

  BOOL wasPlaying = self.isPlaying;
  [self.playerNode stop];

  self.seekOffset = timeInterval;

  [self willChangeValueForKey:@"currentTime"];
  [self didChangeValueForKey:@"currentTime"];

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
        [strongSelf handleTrackCompletion];
      });
    }];
    // clang-format on
    if (wasPlaying) {
      [self.playerNode play];
    }
  }
}

- (void)stop {
  [self.playerNode stop];
  self.isPlaying = NO;
  [self.progressTimer invalidate];
  if (self.currentSecurityScopeURL) {
    [self.currentSecurityScopeURL stopAccessingSecurityScopedResource];
    self.currentSecurityScopeURL = nil;
  }
}

- (void)pause {
  [self.playerNode pause];
}

- (void)play {
  [self.playerNode play];
}

#pragma mark - AudioBufferCallback

- (void)registerAudioBufferCallback:(AudioBufferCallback)callback {
  self.audioBufferCallback = callback;
  [self installAudioTap];
}

- (void)installAudioTap {
  __weak typeof(self) weakSelf = self;
  // clang-format off
  [self.engine.mainMixerNode installTapOnBus:0 bufferSize:2048 format:nil block:^(AVAudioPCMBuffer *_Nonnull buffer, AVAudioTime *_Nonnull _) {
    AVAudioFrameCount frames = buffer.frameLength;
    if (frames == 0) return;
    
    float *mono = (float *)malloc(frames * sizeof(float));
    if (!mono) return;
    
    if (buffer.format.channelCount == 1) {
      memcpy(mono, buffer.floatChannelData[0], frames * sizeof(float));
    } else if (buffer.format.channelCount >= 2) {
      float *left = buffer.floatChannelData[0];
      float *right = buffer.floatChannelData[1];
      for (AVAudioFrameCount i = 0; i < frames; i++) {
        mono[i] = (left[i] + right[i]) * 0.5f;
      }
    } else {
      free(mono);
      return;
    }
    
    if (weakSelf && weakSelf.audioBufferCallback) {
      weakSelf.audioBufferCallback(mono, frames);
    }
    
    free(mono);
  }];
  // clang-format on
}

- (void)unregisterAudioBufferCallback {
  self.audioBufferCallback = nil;
  [self.engine.mainMixerNode removeTapOnBus:0];
}

#pragma mark - Notifications

- (void)notifyDidChangeTrack:(Track *)track {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerTrackDidChangeNotification object:track];
  });
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
      if (strongSelf.playerNode.isPlaying) {
        [strongSelf handleTrackCompletion];
      }
    });
  }];
  // clang-format on

  [[self playerNode] setVolume:self.volume];
  [self.playerNode play];
}

- (void)handleTrackCompletion {
  switch (self.repeatMode) {
  case RepeatModeOne:
    [self playTrack:self.currentTrack];
    break;

  case RepeatModeAll: {
    Track *next = [self.queue nextTrack];
    if (next) {
      [self playTrack:next];
    } else if (self.queue.tracks.count > 0) {
      [self playTrack:self.queue.tracks.firstObject];
    }
    break;
  }

  case RepeatModeOff:
  default:
    [self playNext];
    break;
  }
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
       [self willChangeValueForKey:@"currentTime"];
       [self didChangeValueForKey:@"currentTime"];
  }];
  // clang-format on
}

@end
