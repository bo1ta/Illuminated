//
//  PlaybackManager.h
//  Illuminated
//
//  Created by Alexandru Solomon on 22.01.2026.
//

#import "Cocoa/Cocoa.h"

@class Track;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PlaybackManagerTrackDidChangeNotification;
extern NSString *const PlaybackManagerPlaybackStateDidChangeNotification;
extern NSString *const PlaybackManagerPlaybackProgressDidChangeNotification;

@interface PlaybackManager : NSObject

+ (instancetype)sharedManager;

@property(strong, readonly) Track *currentTrack;
@property(assign, readonly) BOOL isPlaying;
@property(assign, readonly) NSTimeInterval currentTime;
@property(nonatomic, readonly) float volume;

- (void)playTrack:(Track *)track;
- (void)playNext;
- (void)playPrevious;
- (void)togglePlayPause;
- (void)setVolume:(float)volume;
- (void)seekToTime:(NSTimeInterval)timeInterval;
- (void)updateQueue:(NSArray<Track *> *)tracks;
- (void)stop;

- (NSURL *)currentPlaybackURL;

@end

NS_ASSUME_NONNULL_END
