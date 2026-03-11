//
//  ScrobbleTracker.m
//  Illuminated
//
//  Created by Alexandru Solomon on 11.03.2026.
//

#import "ScrobbleTracker.h"
#import "Track.h"
#import "BFTask.h"
#import "TrackPlaybackController.h"
#import "AppPlaybackManager.h"
#import "LFMAuthManager.h"
#import "LastFMSession.h"
#import "LastFMClient.h"

@interface ScrobbleTracker ()

@property(nonatomic, strong) LastFMClient *lastFMClient;
@property(nonatomic, strong) LastFMSession *session;

@property(nonatomic, strong) Track *currentTrack;
@property(nonatomic, strong) NSDate *playbackResumedAt;
@property(nonatomic, assign) NSTimeInterval listenedSeconds;
@property(nonatomic, assign) BOOL scrobbleSubmitted;
@property(nonatomic, strong) NSDate *trackStartedAt;

@property (nonatomic, assign) BOOL isChangingTrack;

@end

@implementation ScrobbleTracker

- (instancetype)initWithLastFMClient:(LastFMClient *)client session:(LastFMSession *)session {
  self = [super init];
  if (self) {
    _lastFMClient = client;
    _session = session;
  }
  return self;
}

- (void)start {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(trackDidChange:)
                                               name:PlaybackManagerTrackDidChangeNotification
                                             object:nil];
  [AppPlaybackManager.sharedManager addObserver:self
                                     forKeyPath:@"isPlaying"
                                        options:NSKeyValueObservingOptionNew
                                        context:nil];
}

#pragma mark - Events

- (void)trackDidChange:(NSNotification *)notification {
  self.isChangingTrack = YES;
  
  [self flushListenedTime];
  
  Track *trackToScrobble = self.currentTrack;
  NSDate *startedAt = self.trackStartedAt;
  
  Track *newTrack = notification.object;
  self.currentTrack = newTrack;
  self.listenedSeconds = 0;
  self.scrobbleSubmitted = NO;
  self.playbackResumedAt = [NSDate date];
  self.trackStartedAt = [NSDate date];
  
  [self checkAndScrobbleTrack:trackToScrobble startedAt:startedAt];
  
  [self sendNowPlaying:newTrack];
  
  self.isChangingTrack = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (![keyPath isEqualToString:@"isPlaying"] || self.isChangingTrack) {
    return;
  }
  
  BOOL isPlaying = [change[NSKeyValueChangeNewKey] boolValue];
  if (isPlaying) {
    self.playbackResumedAt = [NSDate date];
  } else {
    [self flushListenedTime];
    [self checkAndScrobbleTrack:self.currentTrack startedAt:self.trackStartedAt];
  }
}

#pragma mark - Accumulator

- (void)flushListenedTime {
  if (!self.playbackResumedAt) {
    return;
  }
  
  self.listenedSeconds += [[NSDate date] timeIntervalSinceDate:self.playbackResumedAt];
  self.playbackResumedAt = nil;
}

- (void)checkAndScrobbleTrack:(Track *)track startedAt:(NSDate *)startedAt {
  if (!track || self.scrobbleSubmitted) {
    return;
  }
  
  NSTimeInterval duration = AppPlaybackManager.sharedManager.duration;
  if (duration <= 0) {
    return;
  }
  
  NSTimeInterval threshold = MIN(duration / 2.0, 4 * 60);
  if (self.listenedSeconds >= threshold) {
    [self submitScrobbleForTrack:track startedAt:startedAt];
    self.scrobbleSubmitted = YES;
  }
}

#pragma mark - LastFM API

- (void)sendNowPlaying:(Track *)track {
  BFTask *task = [self.lastFMClient updateNowPlayingForTrack:track withSession:self.session];
  [task continueWithBlock:^id(BFTask * task) {
    if (task.error) {
      NSLog(@"ScrobbleTracker: Failed to update nowPlaying for track. Error: %@", task.error.localizedDescription);
    }
    return nil;
  }];
}

- (void)submitScrobbleForTrack:(Track *)track startedAt:(NSDate *)startedAt {
  NSLog(@"Submitting scrobble");
  BFTask *task = [self.lastFMClient scrobbleTrack:track startedAt:startedAt withSession:self.session];
  [task continueWithBlock:^id(BFTask *task) {
    if (task.error) {
      NSLog(@"Error while submitting scrobble: %@", task.error.localizedDescription);
    }
    return nil;
  }];
}

@end
