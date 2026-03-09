//
//  PlaybackController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 09.03.2026.
//

#import <Cocoa/Cocoa.h>
#import "PlaybackItem.h"

@protocol PlaybackController <NSObject>

@property(nonatomic, readonly) BOOL isPlaying;
@property(nullable, nonatomic, readonly) id<PlaybackItem> currentItem;
@property(nullable, nonatomic, readonly) NSURL *currentPlaybackURL;

- (void)play;
- (void)pause;
- (void)togglePlayPause;
- (void)stop;
- (void)setVolume:(float)volume;

@end
