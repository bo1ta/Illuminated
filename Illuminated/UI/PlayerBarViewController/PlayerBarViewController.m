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
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@implementation PlayerBarViewController {
  __weak IBOutlet NSButton *previousButton;
  __weak IBOutlet NSImageView *trackArtwork;
  __weak IBOutlet NSButton *nextButton;
  __weak IBOutlet NSButton *repeatButton;
  __weak IBOutlet NSTextField *trackTitle;
  __weak IBOutlet NSTextField *artistName;
  __weak IBOutlet NSStackView *controlsStackView;
  __weak IBOutlet NSButton *playPauseButton;
  __weak IBOutlet NSTextField *currentTimeLabel;
  __weak IBOutlet NSTextField *totalTimeLabel;
  __weak IBOutlet NSSlider *progressSlider;
  __weak IBOutlet NSSlider *volumeSlider;
  __weak IBOutlet NSTextField *bpmLabel;

  BOOL _isScrubbing;
}

#pragma mark - View Setup

- (void)viewDidLoad {
  [super viewDidLoad];

  [controlsStackView setCustomSpacing:30.0 afterView:nextButton];

  [[PlaybackManager sharedManager] setVolume:volumeSlider.floatValue];

  [self setupNotifications];
  [self updateTrackUI];
  [self updateRepeatButton];
  [self setupMediaKeyControls];
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
    [trackTitle setHidden:YES];
    [artistName setHidden:YES];
    [totalTimeLabel setHidden:YES];
    [currentTimeLabel setHidden:YES];
    [bpmLabel setHidden:YES];
    return;
  }

  [trackTitle setHidden:NO];
  [artistName setHidden:NO];
  [totalTimeLabel setHidden:NO];
  [currentTimeLabel setHidden:NO];

  trackTitle.stringValue = track.title ?: @"Not playing";
  artistName.stringValue = track.artist.name ?: @"";
  totalTimeLabel.stringValue = [self formatTime:track.duration];
  if (track.roundedBPM > 0) {
    [bpmLabel setHidden:NO];
    bpmLabel.stringValue = [NSString stringWithFormat:@"%@", track.roundedBPM];
  } else {
    [bpmLabel setHidden:YES];
  }

  if (track.album.artworkPath) {
    trackArtwork.image = [ArtworkManager loadArtworkAtPath:track.album.artworkPath];
  } else {
    trackArtwork.image = nil;
  }

  [self updatePlaybackState];
  [self updateNowPlayingInfoWithTrack:track artworkImage:trackArtwork.image];
}

- (void)updatePlaybackState {
  BOOL isPlaying = [PlaybackManager sharedManager].isPlaying;

  NSString *imgName = isPlaying ? @"pause.circle.fill" : @"play.circle.fill";
  playPauseButton.image = [NSImage imageWithSystemSymbolName:imgName accessibilityDescription:@""];
}

- (void)updateProgress {
  if (_isScrubbing) return;

  PlaybackManager *manager = [PlaybackManager sharedManager];
  if (manager.currentTrack.duration > 0) {
    double progress = manager.currentTime / manager.currentTrack.duration;
    progressSlider.doubleValue = progress;
    currentTimeLabel.stringValue = [self formatTime:manager.currentTime];
  }
}

- (void)updateRepeatButton {
  PlaybackManager *manager = [PlaybackManager sharedManager];

  switch (manager.repeatMode) {
  case RepeatModeOff:
    repeatButton.image = [NSImage imageWithSystemSymbolName:@"repeat" accessibilityDescription:@"Repeat Off"];
    repeatButton.contentTintColor = [NSColor secondaryLabelColor];
    break;

  case RepeatModeOne:
    repeatButton.image = [NSImage imageWithSystemSymbolName:@"repeat.1" accessibilityDescription:@"Repeat One"];
    repeatButton.contentTintColor = [NSColor systemBlueColor];
    break;

  case RepeatModeAll:
    repeatButton.image = [NSImage imageWithSystemSymbolName:@"repeat" accessibilityDescription:@"Repeat All"];
    repeatButton.contentTintColor = [NSColor systemBlueColor];
    break;
  }
}

#pragma mark - IBActions

- (IBAction)progressDidChange:(NSSlider *)sender {
  _isScrubbing = YES;

  PlaybackManager *manager = [PlaybackManager sharedManager];
  NSTimeInterval newTime = sender.doubleValue * manager.currentTrack.duration;
  [manager seekToTime:newTime];

  currentTimeLabel.stringValue = [self formatTime:newTime];

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
