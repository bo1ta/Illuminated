//
//  PlayerBarViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "PlayerBarViewController.h"
#import "Album.h"
#import "Artist.h"
#import "ArtworkManager.h"
#import "PlaybackManager.h"
#import "Track.h"
#import "TrackService.h"
#import "WaveformView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

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

@end

@implementation PlayerBarViewController {
  BOOL _isScrubbing;
}

#pragma mark - View Setup

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.controlsStackView setCustomSpacing:30.0 afterView:self.nextButton];

  [[PlaybackManager sharedManager] setVolume:self.volumeSlider.floatValue];

  [self setupNotifications];
  [self updateTrackUI];
  [self updateRepeatButton];
  [self setupMediaKeyControls];

  self.waveformView.delegate = self;
  
  PlaybackManager *manager = [PlaybackManager sharedManager];
  [self.waveformView bind:@"progress"
                     toObject:manager
                  withKeyPath:@"progress"
                      options:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)setupNotifications {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(updateTrackUI) name:PlaybackManagerTrackDidChangeNotification object:nil];
  [nc addObserver:self
         selector:@selector(updatePlaybackState)
             name:PlaybackManagerPlaybackStateDidChangeNotification
           object:nil];
  [nc addObserver:self
         selector:@selector(updateProgress)
             name:PlaybackManagerPlaybackProgressDidChangeNotification
           object:nil];
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

- (void)updateTrackUI {
  Track *track = [PlaybackManager sharedManager].currentTrack;
  if (!track) {
    [self.trackTitle setHidden:YES];
    [self.artistName setHidden:YES];
    [self.totalTimeLabel setHidden:YES];
    [self.currentTimeLabel setHidden:YES];
    [self.bpmLabel setHidden:YES];
    return;
  }

  [self.trackTitle setHidden:NO];
  [self.artistName setHidden:NO];
  [self.totalTimeLabel setHidden:NO];
  [self.currentTimeLabel setHidden:NO];

  self.trackTitle.stringValue = track.title ?: @"Not playing";
  self.artistName.stringValue = track.artist.name ?: @"";
  self.totalTimeLabel.stringValue = [self formatTime:track.duration];
  if (track.roundedBPM > 0) {
    [self.bpmLabel setHidden:NO];
    self.bpmLabel.stringValue = [NSString stringWithFormat:@"%@", track.roundedBPM];
  } else {
    [self.bpmLabel setHidden:YES];
  }

  if (track.album.artworkPath) {
    self.trackArtwork.image = [ArtworkManager loadArtworkAtPath:track.album.artworkPath];
  } else {
    self.trackArtwork.image = nil;
  }

  [self updatePlaybackState];
  [self updateNowPlayingInfoWithTrack:track artworkImage:self.trackArtwork.image];
  [self updatePlaybackState];
  [self updateNowPlayingInfoWithTrack:track artworkImage:self.trackArtwork.image];

  [self generateWaveformForTrack:track];
}

- (void)generateWaveformForTrack:(Track *)track {
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
  BOOL isPlaying = [PlaybackManager sharedManager].isPlaying;

  NSString *imgName = isPlaying ? @"pause.circle.fill" : @"play.circle.fill";
  self.playPauseButton.image = [NSImage imageWithSystemSymbolName:imgName accessibilityDescription:@""];
}

- (void)updateProgress {
  if (_isScrubbing) return;

  PlaybackManager *manager = [PlaybackManager sharedManager];

  if (manager.currentTrack.duration > 0) {
    dispatch_async(dispatch_get_main_queue(), ^{
      double progress = manager.currentTime / manager.currentTrack.duration;
      self.waveformView.progress = progress;
      self.currentTimeLabel.stringValue = [self formatTime:manager.currentTime];
    });
  }
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

  self.currentTimeLabel.stringValue = [self formatTime:newTime];

  /// reset flag after a tiny delay to allow the player to catch up
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    self->_isScrubbing = NO;
  });
}

- (IBAction)volumeDidChange:(NSSlider *)sender {
  [[PlaybackManager sharedManager] setVolume:sender.floatValue];
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

  [self updateRepeatButton];
}

- (IBAction)playAction:(id)sender {
  [[PlaybackManager sharedManager] togglePlayPause];
}

- (IBAction)previousAction:(id)sender {
  [[PlaybackManager sharedManager] playPrevious];
}

#pragma mark - Private

- (NSString *)formatTime:(NSTimeInterval)seconds {
  NSInteger mins = (NSInteger)seconds / 60;
  NSInteger secs = (NSInteger)seconds % 60;
  return [NSString stringWithFormat:@"%ld:%02ld", mins, secs];
}

@end
