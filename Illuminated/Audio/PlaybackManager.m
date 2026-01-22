//
//  PlaybackManager.m
//  Illuminated
//
//  Created by Alexandru Solomon on 22.01.2026.
//

#import "PlaybackManager.h"
#import "CoreDataStore.h"
#import <Foundation/Foundation.h>

NSString *const PlaybackManagerTrackDidChangeNotification = @"PlaybackManagerTrackDidChangeNotification";
NSString *const PlaybackManagerPlaybackStateDidChangeNotification =
    @"PlaybackManagerPlaybackStateDidChangeNotification";
NSString *const PlaybackManagerPlaybackProgressDidChangeNotification =
    @"PlaybackManagerPlaybackProgressDidChangeNotification";

@interface PlaybackManager ()<AVAudioPlayerDelegate>

@property(strong) AVAudioPlayer *audioPlayer;
@property(strong) NSTimer *progressTimer;
@property(readwrite) BOOL isPlaying;
@property(strong, nonatomic) NSArray<Track *> *playlist;
@property(readwrite) float currentVolume;

@end

@implementation PlaybackManager
+ (instancetype)sharedManager {
  static PlaybackManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

#pragma mark - Playback

- (void)playTrack:(Track *)track {
  if (!track)
    return;

  NSError *error = nil;
  BOOL isStale = NO;
  NSURL *resolvedURL = [NSURL URLByResolvingBookmarkData:track.urlBookmark
                                                 options:NSURLBookmarkResolutionWithSecurityScope
                                           relativeToURL:nil
                                     bookmarkDataIsStale:&isStale
                                                   error:&error];

  if (error || !resolvedURL) {
    NSLog(@"Failed to resolve track: %@", error);
    return;
  }

  [self.audioPlayer stop];
  [self.progressTimer invalidate];

  [resolvedURL startAccessingSecurityScopedResource];
  self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:resolvedURL error:&error];
  self.audioPlayer.volume = self.currentVolume;

  if (error) {
    NSLog(@"Failed to setup audio player with url %@. Error: %@", resolvedURL, error);
    return;
  }

  self.audioPlayer.delegate = self;
  _currentTrack = track;

  [self.audioPlayer play];
  self.isPlaying = YES;

  [self incrementPlayCountForTrack:track];

  [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerTrackDidChangeNotification object:track];
  [self startTimer];
}

- (void)playNext {
  if (self.playlist.count < 1 || !self.currentTrack)
    return;

  NSUInteger currentIndex = [self.playlist indexOfObject:self.currentTrack];
  if (currentIndex != NSNotFound && currentIndex < self.playlist.count - 1) {
    [self playTrack:self.playlist[currentIndex + 1]];
  }
}

- (void)playPrevious {
  if (self.playlist.count < 1 || !self.currentTrack)
    return;

  /// if we are more than 3 secs into the song, "previous" means restart
  if (self.audioPlayer.currentTime > 3.0) {
    [self seekToTime:0];
    return;
  }

  NSUInteger currentIndex = [self.playlist indexOfObject:self.currentTrack];
  if (currentIndex != NSNotFound && currentIndex > 0) {
    [self playTrack:self.playlist[currentIndex - 1]];
  }
}

- (void)togglePlayPause {
  if (!self.audioPlayer)
    return;

  if (self.isPlaying) {
    [self.audioPlayer pause];
    [self.progressTimer invalidate];
  } else {
    [self.audioPlayer play];
    [self startTimer];
  }

  self.isPlaying = !self.isPlaying;
  [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerPlaybackStateDidChangeNotification
                                                      object:nil];
}

- (void)setVolume:(float)volume {
  self.currentVolume = volume;

  if (!self.audioPlayer)
    return;

  self.audioPlayer.volume = volume;
}

- (void)seekToTime:(NSTimeInterval)timeInterval {
  if (!self.audioPlayer)
    return;

  self.audioPlayer.currentTime = timeInterval;
  [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerPlaybackProgressDidChangeNotification
                                                      object:nil];
}

- (void)updateQueue:(NSArray<Track *> *)tracks {
  self.playlist = tracks;
}

#pragma mark - Helpers

- (void)startTimer {
  [self.progressTimer invalidate];
  __weak typeof(self) weakSelf = self;

  self.progressTimer = [NSTimer
      scheduledTimerWithTimeInterval:0.5
                             repeats:YES
                               block:^(NSTimer *_) {
                                 [[NSNotificationCenter defaultCenter]
                                     postNotificationName:PlaybackManagerPlaybackProgressDidChangeNotification
                                                   object:nil];
                                 if (weakSelf.audioPlayer && !weakSelf.audioPlayer.isPlaying && weakSelf.isPlaying) {
                                   [weakSelf playNext];
                                 }
                               }];
}

- (void)incrementPlayCountForTrack:(Track *)track {
  NSManagedObjectID *trackID = track.objectID;
  [[CoreDataStore writeOnlyStore] performWrite:^id(NSManagedObjectContext *context) {
    Track *object = [context objectWithID:trackID];
    if (!object)
      return nil;

    object.playCount += 1;
    object.lastPlayed = [NSDate new];
    return nil;
  }];
}

- (NSTimeInterval)currentTime {
  return self.audioPlayer.currentTime;
}

- (NSTimeInterval)duration {
  return self.audioPlayer.duration;
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  self.isPlaying = NO;
  [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerPlaybackStateDidChangeNotification
                                                      object:nil];
}

@end
