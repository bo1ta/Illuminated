//
//  RadioPlaybackController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import "RadioPlaybackController.h"
#import "RadioService.h"
#import "RadioStation+PlaybackItem.h"
#import "RadioStation.h"
#import <AVFoundation/AVFoundation.h>

static NSString *const RadioStreamMetadataIcyIdentifier = @"icy/StreamTitle";

@interface RadioPlaybackController ()<AVPlayerItemMetadataOutputPushDelegate>

@property(strong, nullable) AVPlayer *streamPlayer;
@property(strong, nullable) AVPlayerItemMetadataOutput *metadataOutput;
@property(strong, nullable) RadioStation *currentStation;
@property(strong, nullable) NSString *currentStreamTitle;
@property(assign, nonatomic) BOOL isPlaying;
@property(strong, nullable) NSError *lastError;

@property(nonatomic, assign) float volume;

@end

@implementation RadioPlaybackController

#pragma mark - Initialization

- (instancetype)init {
  self = [super init];
  if (self) {
    _isPlaying = NO;
  }
  return self;
}

- (void)dealloc {
  [self stop];
}

#pragma mark - Public Methods

- (id<PlaybackItem>)currentItem {
  return self.currentStation;
}

- (void)setVolume:(float)volume {
  _volume = volume;
  if (self.streamPlayer) {
    [self.streamPlayer setVolume:volume];
  }
}

- (void)playStation:(RadioStation *)station {
  if (!station || !station.url) {
    self.lastError = [NSError errorWithDomain:@"RadioPlaybackController"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid station URL"}];
    return;
  }

  [self stop];

  NSURL *url = [NSURL URLWithString:station.url];
  if (!url) {
    self.lastError =
        [NSError errorWithDomain:@"RadioPlaybackController"
                            code:-2
                        userInfo:@{NSLocalizedDescriptionKey : @"Could not create URL from station URL string"}];
    return;
  }

  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
  [self setupMetadataOutputForPlayerItem:playerItem];

  self.streamPlayer = [AVPlayer playerWithPlayerItem:playerItem];
  [self addPlayerObservers];

  [self.streamPlayer setVolume:self.volume];
  [self.streamPlayer play];

  self.currentStation = station;
  self.currentStreamTitle = nil;
  self.lastError = nil;
  self.isPlaying = YES;

  if (station.serverIDFallback) {
    [RadioService increaseClickCountForStationID:station.serverIDFallback];
  }
}

- (void)pause {
  if (self.streamPlayer && self.isPlaying) {
    [self.streamPlayer pause];
    self.isPlaying = NO;
  }
}

- (void)resume {
  if (self.streamPlayer && !self.isPlaying) {
    [self.streamPlayer play];
    self.isPlaying = YES;
  }
}

- (void)togglePlayPause {
  if (self.isPlaying) {
    [self pause];
  } else {
    [self resume];
  }
}

- (void)stop {
  if (self.streamPlayer) {
    AVPlayerItem *playerItem = self.streamPlayer.currentItem;
    if (playerItem && self.metadataOutput) {
      [playerItem removeOutput:self.metadataOutput];
    }

    [self removePlayerObservers];

    [self.streamPlayer pause];
    self.streamPlayer = nil;
    self.metadataOutput = nil;
  }

  self.isPlaying = NO;
  self.currentStation = nil;
  self.currentStreamTitle = nil;
}

- (void)play {
  [self resume];
}

- (NSURL *)currentPlaybackURL {
  return self.currentItem.playbackURL;
}

#pragma mark - Private Methods

- (void)setupMetadataOutputForPlayerItem:(AVPlayerItem *)playerItem {
  self.metadataOutput = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
  [self.metadataOutput setDelegate:self queue:dispatch_get_main_queue()];
  [playerItem addOutput:self.metadataOutput];
}

- (void)addPlayerObservers {
  [self.streamPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removePlayerObservers {
  @try {
    [self.streamPlayer removeObserver:self forKeyPath:@"status"];
  } @catch (NSException *exception) {
    NSLog(@"RadioPlaybackController: Failed removing observer - %@", exception.reason);
  }
}

- (void)handleStreamFailure {
  self.lastError = [NSError errorWithDomain:@"RadioPlaybackController"
                                       code:-100
                                   userInfo:@{NSLocalizedDescriptionKey : @"Failed to load radio stream"}];
  [self stop];
}

- (void)processMetadataItem:(AVMetadataItem *)item {
  NSLog(@"Radio metadata - identifier: %@, key: %@, value: %@", item.identifier, item.key, item.stringValue);

  NSString *value = item.stringValue;
  if (!value) {
    return;
  }

  if ([item.identifier isEqualToString:RadioStreamMetadataIcyIdentifier]) {
    self.currentStreamTitle = value;
    NSLog(@"All good here");
  }
}

#pragma mark - KVO

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCurrentItem {
  return [NSSet setWithObjects:@"currentStation", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

  if (object == self.streamPlayer && [keyPath isEqualToString:@"status"]) {
    AVPlayerStatus status = self.streamPlayer.status;

    if (status == AVPlayerStatusFailed) {
      [self handleStreamFailure];
    } else if (status == AVPlayerStatusReadyToPlay) {
      NSLog(@"Radio stream ready to play");
    }
  }
}

#pragma mark - AVPlayerItemMetadataOutputPushDelegate

- (void)metadataOutput:(AVPlayerItemMetadataOutput *)output
    didOutputTimedMetadataGroups:(NSArray<AVTimedMetadataGroup *> *)groups
             fromPlayerItemTrack:(AVPlayerItemTrack *)track {

  for (AVTimedMetadataGroup *group in groups) {
    for (AVMetadataItem *item in group.items) {
      [self processMetadataItem:item];
    }
  }
}

@end
