//
//  AppPlaybackManager.m
//  Illuminated
//
//  Created by Alexandru Solomon on 09.03.2026.
//

#import "AppPlaybackManager.h"
#import "TrackPlaybackController.h"
#import "RadioPlaybackController.h"

@interface AppPlaybackManager ()

@property(nonatomic, strong) RadioPlaybackController *radioController;
@property(nonatomic, strong) TrackPlaybackController *trackController;

@property(nonatomic, strong, nullable) id<PlaybackItem> currentItem;
@property(nonatomic, weak, nullable) id<PlaybackController> activeController;

@end

@implementation AppPlaybackManager

#pragma mark - Lifecycle

+ (AppPlaybackManager *)sharedManager {
  static AppPlaybackManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _trackController = [TrackPlaybackController sharedManager];
    _radioController = [[RadioPlaybackController alloc] init];
    _volume = 0.5;
            
    [self setupObservations];
  }
  return self;
}

- (void)dealloc {
  [self cleanUpObservers];
}

#pragma mark - Observation

- (void)setupObservations {
  __weak typeof(self) weakSelf = self;
  
  NSArray *controllers = @[self.trackController, self.radioController];
  NSArray *keyPaths = @[@"isPlaying", @"currentItem"];
  
  for (id controller in controllers) {
    for (NSString *keyPath in keyPaths) {
      [controller addObserver:self
                   forKeyPath:keyPath
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    }
    
    if ([controller isKindOfClass:[TrackPlaybackController class]]) {
      [controller addObserver:self
                   forKeyPath:@"progress"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
      [controller addObserver:self
                   forKeyPath:@"currentTime"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
      [controller addObserver:self
                   forKeyPath:@"duration"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
      [controller addObserver:self
                   forKeyPath:@"isSeekable"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    } else if ([controller isKindOfClass:[RadioPlaybackController class]]) {
      [controller addObserver:self
                   forKeyPath:@"currentStreamTitle"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    }
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (object == self.activeController) {
    [self willChangeValueForKey:keyPath];
    [self didChangeValueForKey:keyPath];
  }
}

- (void)cleanUpObservers {
  for (NSObject *controller in @[self.trackController, self.radioController]) {
    @try {
      [controller removeObserver:self forKeyPath:@"isPlaying"];
      [controller removeObserver:self forKeyPath:@"currentItem"];
      [controller removeObserver:self forKeyPath:@"progress"];
      [controller removeObserver:self forKeyPath:@"currentTime"];
      [controller removeObserver:self forKeyPath:@"duration"];
      [controller removeObserver:self forKeyPath:@"isSeekable"];
      
      if ([controller isKindOfClass:[RadioPlaybackController class]]) {
        [controller removeObserver:self forKeyPath:@"currentStreamTitle"];
        [controller removeObserver:self forKeyPath:@"currentStation"];
      }
    } @catch (NSException *exception) {
      NSLog(@"Error removing observer: %@", exception);
    }
  }
}

#pragma mark - Public getters

- (BOOL)isPlaying {
  return self.activeController.isPlaying;
}

- (NSString *)currentStreamTitle {
  if (self.activeController == self.radioController) {
    return self.radioController.currentStreamTitle;
  }
  return nil;
}

- (id<PlaybackItem>)currentItem {
  return self.activeController.currentItem;
}

- (PlaybackItemType)currentItemType {
  return self.currentItem.type;
}

- (NSURL *)currentPlaybackURL {
  return self.activeController.currentPlaybackURL;
}

- (double)progress {
  if (self.activeController == self.trackController) {
    return self.trackController.progress;
  }
  return 0.0;
}

- (NSTimeInterval)duration {
  if (self.activeController == self.trackController) {
    return self.trackController.duration;
  }
  return 0;
}

- (BOOL)isSeekable {
  return (self.activeController == self.trackController);
}

- (NSTimeInterval)currentTime {
  if (self.activeController == self.trackController) {
    return self.trackController.currentTime;
  }
  return 0.0;
}

- (NSString *)currentTitle {
  return self.currentItem.displayTitle;
}

- (NSString *)currentSubtitle {
  return self.currentItem.subtitle;
}

- (NSImage *)currentArtwork {
  return self.currentItem.artworkImage;
}

- (Track *)currentTrack {
  if (self.activeController == self.trackController) {
    return self.trackController.currentTrack;
  }
  return nil;
}

- (RadioStation *)currentStation {
  if (self.activeController == self.radioController) {
    return self.radioController.currentStation;
  }
  return nil;
}

- (RepeatMode)trackRepeatMode {
  if (self.activeController == self.trackController) {
    return self.trackController.repeatMode;
  }
  return RepeatModeOff;
}

#pragma mark - Default Actions

- (void)playItem:(id<PlaybackItem>)item {
  if (item.type == PlaybackItemTypeTrack) {
    [self playTrack:(Track *)item];
  } else {
    [self playRadioStation: (RadioStation *)item];
  }
}

- (void)togglePlayPause {
  [self.activeController togglePlayPause];
}

- (void)stop {
  [self.activeController stop];
  self.activeController = nil;
}

- (void)setVolume:(float)volume {
  _volume = volume;
  [self.activeController setVolume:volume];
}

#pragma mark - Track Specific Actions

- (void)playNext {
  if (self.activeController == self.trackController) {
    [self.trackController playNext];
  }
}

- (void)playPrevious {
  if (self.activeController == self.trackController) {
    [self.trackController playPrevious];
  }
}

- (void)playTrack:(Track *)track {
  if (self.activeController == self.radioController) {
    [self.radioController stop];
  }
  
  self.activeController = self.trackController;
  
  [self.trackController setVolume:self.volume];
  [self.trackController playTrack:track];
}

- (void)updateQueue:(NSArray<Track *> *)tracks {
  if (self.activeController == self.trackController) {
    [self.trackController updateQueue:tracks];
  }
}

- (void)playRadioStation:(RadioStation *)station {
  if (self.activeController == self.trackController) {
    [self.trackController stop];
  }
  
  self.activeController = self.radioController;
  
  [self.radioController setVolume:self.volume];
  [self.radioController playStation:station];
}

- (void)seekToProgress:(double)progress {
  if (self.activeController == self.trackController) {
    NSTimeInterval time = progress * self.duration;
    [self.trackController seekToTime:time];
  }
}

- (void)seekToTime:(NSTimeInterval)time {
  if (self.activeController == self.trackController) {
    [self.trackController seekToTime:time];
  }
}

- (void)setRepeatMode:(RepeatMode)repeatMode {
  if (self.activeController == self.trackController) {
    [self.trackController setRepeatMode:repeatMode];
  }
}

@end
