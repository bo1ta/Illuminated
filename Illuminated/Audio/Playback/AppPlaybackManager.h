//
//  AppPlaybackManager.h
//  Illuminated
//
//  Created by Alexandru Solomon on 09.03.2026.
//

#import <Cocoa/Cocoa.h>
#import "PlaybackItem.h"
#import "TrackPlaybackController.h"

NS_ASSUME_NONNULL_BEGIN

@class Track, RadioStation;

@interface AppPlaybackManager : NSObject

@property(class, readonly, strong) AppPlaybackManager *sharedManager;

#pragma mark - Unified KVO-observable properties

@property(nonatomic, readonly) BOOL isPlaying;
@property(nonatomic, readonly) id<PlaybackItem> currentItem;
@property(nonatomic, readonly) PlaybackItemType currentItemType;
@property(nonatomic, readonly) NSString *currentTitle;
@property(nonatomic, readonly) NSString *currentSubtitle;
@property(nonatomic, readonly) NSImage *currentArtwork;
@property(nonatomic, assign) float volume;
@property(nonatomic, readonly, nullable) NSURL *currentPlaybackURL;

#pragma mark - Track-specific properties (will be 0/nil for radio)

@property(nonatomic, readonly) double progress;
@property(nonatomic, readonly) NSTimeInterval currentTime;
@property(nonatomic, readonly) NSTimeInterval duration;
@property(nonatomic, readonly) BOOL isSeekable;
@property(nonatomic, readonly, nullable) Track *currentTrack;
@property(nonatomic, readonly) RepeatMode trackRepeatMode;

#pragma mark - Radio-specific properties

@property(nonatomic, readonly) RadioStation *currentStation;
@property(nonatomic, readonly, nullable) NSString *currentStreamTitle;

#pragma mark - Actions

- (void)playItem:(id<PlaybackItem>)item;
- (void)playTrack:(Track *)track;
- (void)playRadioStation:(RadioStation *)station;
- (void)playNext;
- (void)playPrevious;

- (void)togglePlayPause;
- (void)stop;

#pragma mark - Track-specific actions (no-op for radio)

- (void)seekToProgress:(double)progress;
- (void)seekToTime:(NSTimeInterval)time;
- (void)updateQueue:(NSArray<Track *> *)tracks;
- (void)setRepeatMode:(RepeatMode)repeatMode;

@end

NS_ASSUME_NONNULL_END
