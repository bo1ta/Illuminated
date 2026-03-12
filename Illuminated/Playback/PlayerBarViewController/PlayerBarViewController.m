//
//  PlayerBarViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//
//

#import "PlayerBarViewController.h"
#import "Album.h"
#import "AppPlaybackManager.h"
#import "Artist.h"
#import "BFTask.h"
#import "TimeIntervalTransformer.h"
#import "Track.h"
#import "TrackService.h"
#import "WaveformView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface PlayerBarViewController ()<WaveformViewDelegate>

#pragma mark - IBOutlets

@property(weak, nonatomic) IBOutlet WaveformView *waveformView;
@property(weak, nonatomic) IBOutlet NSImageView *trackArtwork;
@property(weak, nonatomic) IBOutlet NSTextField *trackTitle;
@property(weak, nonatomic) IBOutlet NSTextField *artistName;
@property(weak, nonatomic) IBOutlet NSTextField *currentTimeLabel;
@property(weak, nonatomic) IBOutlet NSTextField *totalTimeLabel;
@property(weak, nonatomic) IBOutlet NSTextField *bpmLabel;

@property(weak, nonatomic) IBOutlet NSStackView *controlsStackView;
@property(weak, nonatomic) IBOutlet NSButton *previousButton;
@property(weak, nonatomic) IBOutlet NSButton *playPauseButton;
@property(weak, nonatomic) IBOutlet NSButton *nextButton;
@property(weak, nonatomic) IBOutlet NSButton *repeatButton;
@property(weak, nonatomic) IBOutlet NSSlider *volumeSlider;

#pragma mark - State
@property(nonatomic, assign) BOOL isScrubbing;

@end

@implementation PlayerBarViewController

#pragma mark - Constants

static NSTimeInterval const kScrubberResetDelay = 0.1;

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.controlsStackView setCustomSpacing:30.0 afterView:self.nextButton];
  self.waveformView.delegate = self;

  [self setupBindings];
  [self setupKVO];
  [self setupMediaKeyControls];

  [self updateUIForCurrentItem];
}

- (void)dealloc {
  [self cleanUpObservers];
}

#pragma mark - Setup

- (void)setupUI {
  self.waveformView.delegate = self;
  [self.controlsStackView setCustomSpacing:30.0 afterView:self.nextButton];

  [self updateUIForCurrentItem];
}

- (void)setupBindings {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];

  NSDictionary *timeTransformerOptions = @{NSValueTransformerNameBindingOption : @"TimeIntervalTransformer"};

  [self.currentTimeLabel bind:NSValueBinding
                     toObject:manager
                  withKeyPath:@"currentTime"
                      options:timeTransformerOptions];

  [self.totalTimeLabel bind:NSValueBinding toObject:manager withKeyPath:@"duration" options:timeTransformerOptions];

  [self.volumeSlider bind:NSValueBinding toObject:manager withKeyPath:@"volume" options:nil];

  [self.waveformView bind:@"progress" toObject:manager withKeyPath:@"progress" options:nil];
}

- (void)setupKVO {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
  NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew;

  NSArray *keyPaths = @[ @"isPlaying", @"progress", @"currentItem", @"currentStreamTitle" ];
  for (NSString *keyPath in keyPaths) {
    [manager addObserver:self forKeyPath:keyPath options:options context:nil];
  }
}

- (void)cleanUpObservers {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  NSArray<NSString *> *keyPaths = @[ @"isPlaying", @"progress", @"currentItem", @"currentStreamTitle" ];

  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];

  for (NSString *keyPath in keyPaths) {
    @try {
      [manager removeObserver:self forKeyPath:keyPath];
    } @catch (NSException *exception) {
      NSLog(@"Error removing observer for %@: %@", keyPath, exception);
    }
  }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if (object != [AppPlaybackManager sharedManager]) {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    if ([keyPath isEqualToString:@"isPlaying"]) {
      [self updatePlayPauseButton];
    } else if ([keyPath isEqualToString:@"currentItem"]) {
      [self updateUIForCurrentItem];
    } else if ([keyPath isEqualToString:@"currentStreamTitle"]) {
      self.artistName.stringValue =
          [[AppPlaybackManager sharedManager] currentStreamTitle] ?: self.artistName.stringValue;
    }
  });
}

#pragma mark - UI Updates

- (void)updateUIForCurrentItem {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
  BOOL isRadio = (manager.currentItemType == PlaybackItemTypeRadio);

  [self updateVisibilityForRadioMode:isRadio];
  [self updateTrackInfo];
  [self updateNowPlayingInfo];

  if (!isRadio && manager.currentItem) {
    [self loadWaveformForCurrentTrack];
  }
}

- (void)updateVisibilityForRadioMode:(BOOL)isRadio {
  self.totalTimeLabel.hidden = isRadio;
  self.currentTimeLabel.hidden = isRadio;
  self.bpmLabel.hidden = isRadio;
  self.waveformView.hidden = isRadio;
  self.repeatButton.hidden = isRadio;
  self.previousButton.hidden = isRadio;
  self.nextButton.hidden = isRadio;

  self.trackTitle.hidden = NO;
  self.artistName.hidden = NO;
  self.trackArtwork.hidden = NO;
}

- (void)updateTrackInfo {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
  self.trackTitle.stringValue = manager.currentTitle ?: @"";
  self.artistName.stringValue = manager.currentItem.subtitle ?: @"";
  self.trackArtwork.image = manager.currentItem.artworkImage;

  if (manager.currentTrack.bpm) {
    self.bpmLabel.floatValue = manager.currentTrack.bpm;
  }
}

- (void)updatePlayPauseButton {
  BOOL isPlaying = [AppPlaybackManager sharedManager].isPlaying;
  NSString *imageName = isPlaying ? @"pause.circle.fill" : @"play.circle.fill";
  self.playPauseButton.image = [NSImage imageWithSystemSymbolName:imageName accessibilityDescription:nil];
}

- (void)loadWaveformForCurrentTrack {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];

  if (manager.currentItemType != PlaybackItemTypeTrack) return;

  Track *track = (Track *)manager.currentItem;
  NSURL *url = [[TrackPlaybackController sharedManager] currentPlaybackURL];

  if (!url || !track) return;

  self.waveformView.waveformImage = nil;

  __weak typeof(self) weakSelf = self;
  [[TrackService getWaveformForTrack:track resolvedURL:url size:self.waveformView.bounds.size]
      continueOnMainThreadWithBlock:^id(BFTask<NSImage *> *task) {
        if (task.result) {
          weakSelf.waveformView.waveformImage = task.result;
        } else {
          NSLog(@"Error loading waveform: %@", task.error);
        }
        return nil;
      }];
}

#pragma mark - Media Player

- (void)updateNowPlayingInfo {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
  NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];

  if (manager.currentItemType == PlaybackItemTypeTrack) {
    Track *track = (Track *)manager.currentItem;
    nowPlayingInfo[MPMediaItemPropertyTitle] = track.title ?: @"Unknown Track";
    nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist.name ?: @"Unknown Artist";
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album.title ?: @"Unknown Album";
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(manager.duration);
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(manager.currentTime);
  } else {
    nowPlayingInfo[MPMediaItemPropertyTitle] = manager.currentTitle ?: @"Radio";
    nowPlayingInfo[MPMediaItemPropertyArtist] = manager.currentSubtitle ?: @"";
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(0);
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(0);
  }

  nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @(manager.isPlaying ? 1.0 : 0.0);

  NSImage *artwork = manager.currentArtwork;
  if (artwork) {
    MPMediaItemArtwork *mediaArtwork =
        [[MPMediaItemArtwork alloc] initWithBoundsSize:artwork.size
                                        requestHandler:^NSImage *(CGSize _) { return artwork; }];
    nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork;
  }

  [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
}

#pragma mark - Media Key Controls

- (void)setupMediaKeyControls {
  MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

  [commandCenter.togglePlayPauseCommand setEnabled:YES];
  [commandCenter.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *_) {
    [[AppPlaybackManager sharedManager] togglePlayPause];
    return MPRemoteCommandHandlerStatusSuccess;
  }];

  [commandCenter.nextTrackCommand setEnabled:YES];
  [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *_) {
    [[AppPlaybackManager sharedManager] playNext];
    return MPRemoteCommandHandlerStatusSuccess;
  }];

  [commandCenter.previousTrackCommand setEnabled:YES];
  [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *_) {
    [[AppPlaybackManager sharedManager] playPrevious];
    return MPRemoteCommandHandlerStatusSuccess;
  }];
}

#pragma mark - IBActions

- (IBAction)playAction:(id)sender {
  [[AppPlaybackManager sharedManager] togglePlayPause];
}

- (IBAction)nextAction:(id)sender {
  [[AppPlaybackManager sharedManager] playNext];
}

- (IBAction)previousAction:(id)sender {
  [[AppPlaybackManager sharedManager] playPrevious];
}

- (IBAction)repeatAction:(id)sender {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
  if (manager.currentItemType == PlaybackItemTypeRadio) {
    return;
  }

  RepeatMode repeatMode = RepeatModeOff;
  switch (manager.trackRepeatMode) {
  case RepeatModeOff:
    manager.repeatMode = RepeatModeOne;
    break;
  case RepeatModeOne:
    manager.repeatMode = RepeatModeAll;
    break;
  case RepeatModeAll:
    manager.repeatMode = RepeatModeOff;
    break;
  }
  [self updateRepeatButtonWithMode:repeatMode];
}

- (void)updateRepeatButtonWithMode:(RepeatMode)repeatMode {
  switch (repeatMode) {
  case RepeatModeOff:
    self.repeatButton.image = [NSImage imageWithSystemSymbolName:@"repeat" accessibilityDescription:@"Repeat Off"];
    self.repeatButton.contentTintColor = [NSColor secondaryLabelColor];
    break;

  case RepeatModeOne:
    self.repeatButton.image = [NSImage imageWithSystemSymbolName:@"repeat.1" accessibilityDescription:@"Repeat One"];
    self.repeatButton.contentTintColor = [NSColor systemBlueColor];
    break;

  case RepeatModeAll:
    self.repeatButton.image = [NSImage imageWithSystemSymbolName:@"repeat" accessibilityDescription:@"Repeat All"];
    self.repeatButton.contentTintColor = [NSColor systemBlueColor];
    break;
  }
}

#pragma mark - WaveformViewDelegate

- (void)waveformView:(WaveformView *)waveformView didSeekToProgress:(double)progress {
  self.isScrubbing = YES;

  [[AppPlaybackManager sharedManager] seekToProgress:progress];

  // Reset flag after a tiny delay
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    self.isScrubbing = NO;
  });
}

@end
