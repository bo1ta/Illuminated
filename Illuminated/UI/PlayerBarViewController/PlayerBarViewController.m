//
//  PlayerBarViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//
//

#import "PlayerBarViewController.h"
#import "Album.h"
#import "Artist.h"
#import "ArtworkManager.h"
#import "BFTask.h"
#import "PlaybackManager.h"
#import "Track.h"
#import "TrackService.h"
#import "WaveformView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "RadioViewController.h"

NSString *const PlaybackSourceDidChangeToLibraryNotification = @"PlaybackSourceDidChangeToLibraryNotification";
NSString *const PlaybackDidToggleNotification = @"PlaybackDidToggleNotification";

@interface PlayerBarViewController ()<WaveformViewDelegate>

@property(weak, nonatomic) IBOutlet WaveformView *waveformView;
@property(weak, nonatomic) IBOutlet NSButton *previousButton;
@property(weak, nonatomic) IBOutlet NSImageView *trackArtwork;
@property(weak, nonatomic) IBOutlet NSButton *nextButton;
@property(weak, nonatomic) IBOutlet NSButton *repeatButton;
@property(weak, nonatomic) IBOutlet NSTextField *trackTitle;
@property(weak, nonatomic) IBOutlet NSTextField *artistName;
@property(weak, nonatomic) IBOutlet NSStackView *controlsStackView;
@property(weak, nonatomic) IBOutlet NSButton *playPauseButton;
@property(weak, nonatomic) IBOutlet NSTextField *currentTimeLabel;
@property(weak, nonatomic) IBOutlet NSTextField *totalTimeLabel;
@property(weak, nonatomic) IBOutlet NSSlider *volumeSlider;
@property(weak, nonatomic) IBOutlet NSTextField *bpmLabel;

@property(nonatomic, assign) PlaybackSource currentPlaybackSource;
@property(nonatomic, assign) BOOL isScrubbing;
@property(nonatomic, assign) BOOL isPlaying;

@end

@implementation PlayerBarViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.controlsStackView setCustomSpacing:30.0 afterView:self.nextButton];

  self.waveformView.delegate = self;

  [self setupBindings];
  [self setupObservers];
  [self setupMediaKeyControls];
}

- (void)dealloc {
  [[PlaybackManager sharedManager] removeObserver:self forKeyPath:@"playing"];
  [[PlaybackManager sharedManager] removeObserver:self forKeyPath:@"repeatMode"];

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self.trackTitle unbind:NSValueBinding];
  [self.artistName unbind:NSValueBinding];
  [self.volumeSlider unbind:NSValueBinding];
  [self.currentTimeLabel unbind:NSValueBinding];
  [self.totalTimeLabel unbind:NSValueBinding];
  [self.waveformView unbind:@"progress"];
}

#pragma mark = Bindings

- (void)setupBindings {
  PlaybackManager *manager = [PlaybackManager sharedManager];

  [self.trackTitle bind:NSValueBinding
               toObject:manager
            withKeyPath:@"currentTrack.title"
                options:@{NSNullPlaceholderBindingOption : @"Not playing"}];

  [self.artistName bind:NSValueBinding
               toObject:manager
            withKeyPath:@"currentTrack.artist.name"
                options:@{NSNullPlaceholderBindingOption : @""}];

  [self.currentTimeLabel bind:NSValueBinding
                     toObject:manager
                  withKeyPath:@"currentTime"
                      options:@{NSValueTransformerNameBindingOption : @"TimeIntervalTransformer"}];

  [self.totalTimeLabel bind:NSValueBinding
                   toObject:manager
                withKeyPath:@"duration"
                    options:@{NSValueTransformerNameBindingOption : @"TimeIntervalTransformer"}];

  [self.volumeSlider bind:NSValueBinding toObject:manager withKeyPath:@"volume" options:nil];
  [manager setVolume:0.5];

  [self.waveformView bind:@"progress" toObject:manager withKeyPath:@"progress" options:nil];
}

- (void)setupObservers {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(updateTrackUI)
                 name:PlaybackManagerTrackDidChangeNotification
               object:nil];
  [center addObserver:self
             selector:@selector(artworkDidChange:)
                 name:@"ArtworkDidChangeNotification"
               object:nil];
  [center addObserver:self
             selector:@selector(updateRadioUI:)
                 name:RadioStationWillStartPlayingNotification
               object:nil];
  [center addObserver:self
             selector:@selector(updateRadioUI:)
                 name:RadioStationStreamTitleUserInfoKey
               object:nil];
  
  PlaybackManager *manager = [PlaybackManager sharedManager];
  [manager addObserver:self
            forKeyPath:@"playing"
               options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
               context:nil];
  [manager addObserver:self
            forKeyPath:@"repeatMode"
               options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
               context:nil];
}

- (void)artworkDidChange:(NSNotification *)notification {
  Album *changedAlbum = notification.object;
  Track *currentTrack = [PlaybackManager sharedManager].currentTrack;
  
  if (currentTrack.album == changedAlbum) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self updateArtworkImageForTrack:currentTrack];
    });
  }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  if (object == [PlaybackManager sharedManager]) {
    if ([keyPath isEqualToString:@"playing"]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePlaybackState];
      });
    } else if ([keyPath isEqualToString:@"repeatMode"]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self updateRepeatButton];
      });
    } else if ([keyPath isEqualToString:@"currentArtworkPath"]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self updateArtworkImageForTrack:[[PlaybackManager sharedManager] currentTrack]];
      });
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - Media Play

- (void)setupMediaKeyControls {
  MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

  [commandCenter.togglePlayPauseCommand setEnabled:YES];
  [commandCenter.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *_) {
    [[PlaybackManager sharedManager] togglePlayPause];
    return MPRemoteCommandHandlerStatusSuccess;
  }];

  [commandCenter.nextTrackCommand setEnabled:YES];
  [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *_) {
    [[PlaybackManager sharedManager] playNext];
    return MPRemoteCommandHandlerStatusSuccess;
  }];

  [commandCenter.previousTrackCommand setEnabled:YES];
  [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *_) {
    [[PlaybackManager sharedManager] playPrevious];
    return MPRemoteCommandHandlerStatusSuccess;
  }];
}

- (void)updateNowPlayingInfoWithTrack:(Track *)track artworkImage:(nullable NSImage *)artwork {
  NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionary];
  nowPlayingInfo[MPMediaItemPropertyTitle] = track.title ?: @"Unknown Track";
  nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist.name ?: @"Unknown Artist";
  nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album.title ?: @"Unknown Album";
  nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = @(track.duration);

  nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @([[PlaybackManager sharedManager] currentTime]);
  nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = @([[PlaybackManager sharedManager] isPlaying] ? 1.0 : 0.0);

  if (artwork) {
    MPMediaItemArtwork *mediaArtwork =
        [[MPMediaItemArtwork alloc] initWithBoundsSize:artwork.size
                                        requestHandler:^NSImage *(CGSize _) { return artwork; }];
    nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaArtwork;
  }

  [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nowPlayingInfo;
}

#pragma mark - UI updates

- (void)updateRadioUI:(NSNotification *)notification {
  [self setCurrentPlaybackSource:PlaybackSourceRadio];
  
  self.playPauseButton.image = [NSImage imageWithSystemSymbolName:@"pause.circle.fill" accessibilityDescription:@""];
  
  [self.totalTimeLabel setHidden:YES];
  [self.currentTimeLabel setHidden:YES];
  [self.bpmLabel setHidden:YES];
  [self.waveformView setHidden:YES];
  
  NSString *radioStationTitle = notification.userInfo[RadioStationTitleUserInfoKey];
  if (radioStationTitle) {
    self.trackTitle.stringValue = radioStationTitle;
    [self.trackTitle setHidden:NO];
  }
  
  NSString *radioStreamTitle = notification.userInfo[RadioStationStreamTitleUserInfoKey];
  if (radioStreamTitle) {
    self.artistName.stringValue = radioStreamTitle;
    [self.artistName setHidden:NO];
  }
}

- (void)setCurrentPlaybackSource:(PlaybackSource)currentPlaybackSource {
  _currentPlaybackSource = currentPlaybackSource;
  
  if (currentPlaybackSource == PlaybackSourceRadio) {
    [[PlaybackManager sharedManager] stop];
  } else {
    [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackSourceDidChangeToLibraryNotification object:nil];
  }
}

- (void)updateTrackUI {
  Track *track = [PlaybackManager sharedManager].currentTrack;
  if (!track) {
    [self.trackTitle setHidden:YES];
    [self.artistName setHidden:YES];
    [self.totalTimeLabel setHidden:YES];
    [self.currentTimeLabel setHidden:YES];
    [self.bpmLabel setHidden:YES];
    [self.waveformView setHidden:YES];
    return;
  }

  [self setCurrentPlaybackSource:PlaybackSourceLibrary];
  [self.trackTitle setHidden:NO];
  [self.artistName setHidden:NO];
  [self.totalTimeLabel setHidden:NO];
  [self.currentTimeLabel setHidden:NO];

  if (track.roundedBPM > 0) {
    [self.bpmLabel setHidden:NO];
    self.bpmLabel.stringValue = [NSString stringWithFormat:@"%@", track.roundedBPM];
  } else {
    [self.bpmLabel setHidden:YES];
  }

  [self updateArtworkImageForTrack:track];

  [self updateNowPlayingInfoWithTrack:track artworkImage:self.trackArtwork.image];

  [self generateWaveformForTrack:track];
}

- (void)updateArtworkImageForTrack:(Track *)track {
  self.trackArtwork.image = [TrackService loadArtworkForTrack:track withPlaceholderSize:self.trackArtwork.bounds.size];
}

- (void)generateWaveformForTrack:(Track *)track {
  [self.waveformView setHidden:NO];
  self.waveformView.waveformImage = nil;

  NSURL *url = [[PlaybackManager sharedManager] currentPlaybackURL];
  if (!url) return;

  __weak typeof(self) weakSelf = self;

  [[TrackService getWaveformForTrack:track resolvedURL:url size:self.waveformView.bounds.size]
      continueOnMainThreadWithBlock:^id(BFTask<NSImage *> *task) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (task.result) {
          strongSelf.waveformView.waveformImage = task.result;
        } else {
          NSLog(@"Error loading waveform image: %@", task.error);
        }
        return nil;
      }];
}

- (void)updatePlaybackState {
  if (self.currentPlaybackSource == PlaybackSourceRadio) {
    return;
  }
  
  BOOL isPlaying = [PlaybackManager sharedManager].isPlaying;

  NSString *imgName = isPlaying ? @"pause.circle.fill" : @"play.circle.fill";
  self.playPauseButton.image = [NSImage imageWithSystemSymbolName:imgName accessibilityDescription:@""];
  self.isPlaying = isPlaying;
}

- (void)updateRepeatButton {
  PlaybackManager *manager = [PlaybackManager sharedManager];

  switch (manager.repeatMode) {
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

#pragma mark - IBActions

#pragma mark - WaveformViewDelegate

- (void)waveformView:(WaveformView *)waveformView didSeekToProgress:(double)progress {
  _isScrubbing = YES;

  PlaybackManager *manager = [PlaybackManager sharedManager];
  NSTimeInterval newTime = progress * manager.currentTrack.duration;
  [manager seekToTime:newTime];

  /// reset flag after a tiny delay to allow the player to catch up
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    self->_isScrubbing = NO;
  });
}

- (IBAction)nextAction:(id)sender {
  [[PlaybackManager sharedManager] playNext];
}

- (IBAction)repeatAction:(id)sender {
  PlaybackManager *manager = [PlaybackManager sharedManager];
  switch (manager.repeatMode) {
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
}

- (IBAction)playAction:(id)sender {
  if (self.currentPlaybackSource == PlaybackSourceLibrary) {
    [[PlaybackManager sharedManager] togglePlayPause];
  } else {
    [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackDidToggleNotification object:nil];
  }
}

- (IBAction)previousAction:(id)sender {
  [[PlaybackManager sharedManager] playPrevious];
}

@end

// Value Transformer for Time Interval
@interface TimeIntervalTransformer : NSValueTransformer
@end

@implementation TimeIntervalTransformer

+ (Class)transformedValueClass {
  return [NSString class];
}
+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (id)transformedValue:(id)value {
  if (![value respondsToSelector:@selector(doubleValue)]) return @"0:00";
  NSTimeInterval seconds = [value doubleValue];
  NSInteger mins = (NSInteger)seconds / 60;
  NSInteger secs = (NSInteger)seconds % 60;
  return [NSString stringWithFormat:@"%ld:%02ld", mins, secs];
}

@end
