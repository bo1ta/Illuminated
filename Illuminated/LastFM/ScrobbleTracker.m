//
//  ScrobbleTracker.m
//  Illuminated
//
//  Created by Alexandru Solomon on 11.03.2026.
//

#import "ScrobbleTracker.h"
#import "AppPlaybackManager.h"
#import "BFTask.h"
#import "LFMAuthManager.h"
#import "LastFMClient.h"
#import "LastFMSession.h"
#import "Track.h"
#import "TrackPlaybackController.h"

@interface ScrobbleTracker ()

@property(nonatomic, strong) LastFMClient *lastFMClient;
@property(nonatomic, strong) LastFMSession *session;
@property(nonatomic, strong) NSTimer *pollingTimer;
@property(nonatomic, strong) Track *lastScrobbledTrack;

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
  self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                       target:self
                                                     selector:@selector(checkCurrentPlayback)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)checkCurrentPlayback {
  Track *currentTrack = AppPlaybackManager.sharedManager.currentTrack;
  NSTimeInterval currentTime = AppPlaybackManager.sharedManager.currentTime;
  NSTimeInterval duration = AppPlaybackManager.sharedManager.duration;
  BOOL isPlaying = AppPlaybackManager.sharedManager.isPlaying;

  if (!currentTrack || !isPlaying) return;

  if ([self.lastScrobbledTrack.uniqueID isEqual:currentTrack.uniqueID]) return;

  NSTimeInterval threshold = MIN(duration * 0.5, 240.0);

  if (duration < 30.0) return;

  if (currentTime >= threshold) {
    [self.lastFMClient scrobbleTrack:currentTrack
                           startedAt:[NSDate dateWithTimeIntervalSinceNow:-currentTime]
                         withSession:self.session];

    self.lastScrobbledTrack = currentTrack;
  }
}

@end
