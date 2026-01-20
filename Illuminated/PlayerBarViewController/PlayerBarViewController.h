//
//  PlayerBarViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Cocoa/Cocoa.h>

@class Track;

NS_ASSUME_NONNULL_BEGIN

@interface PlayerBarViewController : NSViewController

@property(nonatomic, strong, nullable) Track *currentTrack;
@property(nonatomic, readonly) BOOL isPlaying;
@property(nonatomic) float volume;

- (void)play;
- (void)pause;
- (void)togglePlayPause;
- (void)next;
- (void)previous;

@end

NS_ASSUME_NONNULL_END
