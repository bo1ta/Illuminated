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

@property(strong, readonly) Track *currentTrack;
@property(assign, readonly) BOOL isPlaying;
@property(assign, readonly) NSTimeInterval currentTime;
@property(nonatomic, readonly) float volume;

@property(nonatomic) RepeatMode repeatMode;

- (void)playTrack:(Track *)track;
- (void)playNext;
- (void)playPrevious;
- (void)togglePlayPause;
- (void)setVolume:(float)volume;
- (void)seekToTime:(NSTimeInterval)timeInterval;
- (void)updateQueue:(NSArray<Track *> *)tracks;
- (void)stop;

- (NSURL *)currentPlaybackURL;

- (void)registerAudioBufferCallback:(AudioBufferCallback)callback;
- (void)unregisterAudioBufferCallback;

@end

NS_ASSUME_NONNULL_END
