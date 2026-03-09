//
//  RadioPlaybackController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import <Foundation/Foundation.h>
#import "PlaybackController.h"

@class RadioStation;

NS_ASSUME_NONNULL_BEGIN

@interface RadioPlaybackController : NSObject<PlaybackController>

@property (readonly, nonatomic, nullable) RadioStation *currentStation;
@property (readonly, nonatomic) BOOL isPlaying;
@property (readonly, nonatomic, nullable) NSString *currentStreamTitle;
@property (readonly, nonatomic, nullable) NSError *lastError;

- (void)playStation:(RadioStation *)station;
- (void)pause;
- (void)resume;
- (void)togglePlayPause;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
