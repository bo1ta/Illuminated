//
//  PlayerBarViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "PlayerBarViewController.h"
#import "Artist.h"
#import "Track.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerBarViewController ()

@end

@implementation PlayerBarViewController {
  NSImageView *_trackArtwork;
  NSTextField *_trackTitle;
  NSTextField *_artistName;
  NSButton *_previousButton;
  NSButton *_playPauseButton;
  NSButton *_nextButton;
  NSSlider *_progressSlider;
  NSTextField *_currentTimeLabel;
  NSTextField *_totalTimeLabel;
  NSSlider *_volumeSlider;

  AVAudioPlayer *_audioPlayer;
  NSTimer *_progressTimer;
}

- (void)loadView {
  self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 800, 80)];
  self.view.wantsLayer = YES;
  self.view.layer.backgroundColor = [[NSColor controlBackgroundColor] CGColor];

  [self setupViews];
  [self setupConstraints];
}

- (void)setupViews {
  _trackArtwork = [[NSImageView alloc] init];
  _trackArtwork.imageScaling = NSImageScaleProportionallyUpOrDown;
  _trackArtwork.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_trackArtwork];

  _trackTitle = [self labelWithFont:[NSFont systemFontOfSize:13 weight:NSFontWeightMedium]];
  [self.view addSubview:_trackTitle];

  _artistName = [self labelWithFont:[NSFont systemFontOfSize:11]];
  _artistName.textColor = [NSColor secondaryLabelColor];
  [self.view addSubview:_artistName];

  _previousButton = [self buttonWithImageName:NSImageNameGoBackTemplate action:@selector(previousAction:)];
  [self.view addSubview:_previousButton];

  _playPauseButton = [self buttonWithImageName:NSImageNameTouchBarPlayTemplate
                                        action:@selector(togglePlayPauseAction:)];
  _playPauseButton.bezelStyle = NSBezelStyleCircular;
  [self.view addSubview:_playPauseButton];

  _nextButton = [self buttonWithImageName:NSImageNameGoForwardTemplate action:@selector(nextAction:)];
  [self.view addSubview:_nextButton];

  _currentTimeLabel = [self labelWithFont:[NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular]];
  [self.view addSubview:_currentTimeLabel];

  _progressSlider = [[NSSlider alloc] init];
  _progressSlider.minValue = 0;
  _progressSlider.maxValue = 1;
  _progressSlider.target = self;
  _progressSlider.action = @selector(progressDidChange:);
  _progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_progressSlider];

  _totalTimeLabel = [self labelWithFont:[NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular]];
  [self.view addSubview:_totalTimeLabel];

  _volumeSlider = [[NSSlider alloc] init];
  _volumeSlider.minValue = 0;
  _volumeSlider.maxValue = 1;
  _volumeSlider.floatValue = 0.5;
  _volumeSlider.target = self;
  _volumeSlider.action = @selector(volumeDidChange:);
  _volumeSlider.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_volumeSlider];
}

- (void)setupConstraints {
  NSDictionary *views = @{
    @"artwork" : _trackArtwork,
    @"title" : _trackTitle,
    @"artist" : _artistName,
    @"prev" : _previousButton,
    @"play" : _playPauseButton,
    @"next" : _nextButton,
    @"currentTime" : _currentTimeLabel,
    @"progress" : _progressSlider,
    @"totalTime" : _totalTimeLabel,
    @"volume" : _volumeSlider
  };

  NSDictionary *metrics = @{@"margin" : @20, @"spacing" : @8, @"artworkSize" : @60, @"buttonSize" : @32};

  // Horizontal layout
  [self.view addConstraints:[NSLayoutConstraint
                                constraintsWithVisualFormat:
                                    @"H:|-margin-[artwork(artworkSize)]-margin-[title]->=margin-[prev(buttonSize)]-"
                                    @"spacing-[play(buttonSize)]-spacing-[next(buttonSize)]->=margin-[currentTime]-"
                                    @"spacing-[progress(>=200)]-spacing-[totalTime]-margin-[volume(100)]-margin-|"
                                                    options:0
                                                    metrics:metrics
                                                      views:views]];

  // Vertical layout
  [NSLayoutConstraint activateConstraints:@[
    // Artwork - centered vertically
    [_trackArtwork.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [_trackArtwork.heightAnchor constraintEqualToConstant:60],

    // Track info - stacked
    [_trackTitle.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-8],
    [_artistName.topAnchor constraintEqualToAnchor:_trackTitle.bottomAnchor constant:2],

    // Buttons - centered
    [_previousButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [_playPauseButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [_nextButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],

    // Progress - centered
    [_currentTimeLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [_progressSlider.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [_totalTimeLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    [_volumeSlider.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
  ]];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
}

#pragma mark - Helper Methods

- (NSTextField *)labelWithFont:(NSFont *)font {
  NSTextField *label = [[NSTextField alloc] init];
  label.bordered = NO;
  label.editable = NO;
  label.backgroundColor = [NSColor clearColor];
  label.font = font;
  label.translatesAutoresizingMaskIntoConstraints = NO;
  return label;
}

- (NSButton *)buttonWithImageName:(NSImageName)imageName action:(SEL)action {
  NSButton *button = [NSButton buttonWithImage:[NSImage imageNamed:imageName] target:self action:action];
  button.bordered = NO;
  button.translatesAutoresizingMaskIntoConstraints = NO;
  return button;
}

#pragma mark - Public API

- (void)setCurrentTrack:(Track *)track {
  _currentTrack = track;

  _trackTitle.stringValue = track.title ?: @"";
  _artistName.stringValue = track.artist.name ?: @"";

  _totalTimeLabel.stringValue = [self formatTime:track.duration];
  _currentTimeLabel.stringValue = @"0:00";
  _progressSlider.doubleValue = 0;

  [self playTrack:track];
}

- (void)playTrack:(Track *)track {

  BOOL isStale = NO;
  NSError *error = nil;

  // Convert the blob back into a URL
  NSURL *resolvedURL = [NSURL URLByResolvingBookmarkData:track.urlBookmark
                                                 options:NSURLBookmarkResolutionWithSecurityScope
                                           relativeToURL:nil
                                     bookmarkDataIsStale:&isStale
                                                   error:&error];
  NSLog(@"Playing track with url: %@", resolvedURL);
  if (error) {
    NSLog(@"Error resolving URL: %@", error);
  } else if (resolvedURL) {
    [resolvedURL startAccessingSecurityScopedResource];

    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:resolvedURL error:nil];
    _audioPlayer.volume = _volumeSlider.floatValue;
    [self play];

    // Note: In a real app, you'd call [resolvedURL stopAccessingSecurityScopedResource]
    // when the song finishes or the player is destroyed.
  }
}

- (void)play {
  [_audioPlayer play];
  _isPlaying = YES;
  _playPauseButton.image = [NSImage imageNamed:NSImageNameTouchBarPauseTemplate];

  // Start progress timer
  _progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                    target:self
                                                  selector:@selector(updateProgress)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)pause {
  [_audioPlayer pause];
  _isPlaying = NO;
  _playPauseButton.image = [NSImage imageNamed:NSImageNameTouchBarPlayTemplate];
  [_progressTimer invalidate];
  _progressTimer = nil;
}

- (void)togglePlayPause {
  if (_isPlaying) {
    [self pause];
  } else {
    [self play];
  }
}

- (void)next {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayerRequestNextTrack" object:nil];
}

- (void)previous {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayerRequestPreviousTrack" object:nil];
}

#pragma mark - Actions

- (void)togglePlayPauseAction:(id)sender {
  [self togglePlayPause];
}

- (void)nextAction:(id)sender {
  [self next];
}

- (void)previousAction:(id)sender {
  [self previous];
}

- (void)progressDidChange:(NSSlider *)slider {
  if (_audioPlayer) {
    _audioPlayer.currentTime = slider.doubleValue * _audioPlayer.duration;
  }
}

- (void)volumeDidChange:(NSSlider *)slider {
  _volume = slider.floatValue;
  _audioPlayer.volume = _volume;
}

#pragma mark - Private

- (void)updateProgress {
  if (_audioPlayer) {
    double progress = _audioPlayer.currentTime / _audioPlayer.duration;
    _progressSlider.doubleValue = progress;
    _currentTimeLabel.stringValue = [self formatTime:_audioPlayer.currentTime];
  }
}

- (NSString *)formatTime:(NSTimeInterval)seconds {
  NSInteger mins = (NSInteger)seconds / 60;
  NSInteger secs = (NSInteger)seconds % 60;
  return [NSString stringWithFormat:@"%ld:%02ld", mins, secs];
}

@end
