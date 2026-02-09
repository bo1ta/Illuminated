//
//  PlaybackManager.h
//  Illuminated
//
//  Created by Alexandru Solomon on 22.01.2026.
//

#import "AVFoundation/AVFoundation.h"
#import "Cocoa/Cocoa.h"

@class Track;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Constants

extern NSString *const PlaybackManagerTrackDidChangeNotification;
extern NSString *const PlaybackManagerPlaybackStateDidChangeNotification;
extern NSString *const PlaybackManagerPlaybackProgressDidChangeNotification;

#pragma mark - Types

typedef NS_ENUM(NSInteger, RepeatMode) { RepeatModeOff, RepeatModeOne, RepeatModeAll };

typedef void (^AudioBufferCallback)(const float *monoData, AVAudioFrameCount length);

#pragma mark - PlaybackManager Interface

@interface PlaybackManager : NSObject

+ (instancetype)sharedManager;

@property(strong, readonly, nullable) Track *currentTrack;
@property(assign, readonly, getter=isPlaying) BOOL playing;
@property(assign, readonly) NSTimeInterval currentTime;
@property(assign, readonly) NSTimeInterval duration;
@property(nonatomic, assign) float volume;

@property(nonatomic) RepeatMode repeatMode;

@property(nonatomic, readonly) double progress;

#pragma mark - Playback

- (void)playTrack:(Track *)track;
- (void)playNext;
- (void)playPrevious;
- (void)togglePlayPause;
- (void)stop;

- (nullable NSURL *)currentPlaybackURL;

#pragma mark - Controls

- (void)seekToTime:(NSTimeInterval)timeInterval;
- (void)updateQueue:(NSArray<Track *> *)tracks;

#pragma mark - Audio Buffer Registration

- (void)registerAudioBufferCallback:(AudioBufferCallback)callback;
- (void)unregisterAudioBufferCallback;

@end

NS_ASSUME_NONNULL_END
