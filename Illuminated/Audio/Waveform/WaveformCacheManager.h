//
//  WaveformCacheManager.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WaveformCacheManager : NSObject

+ (NSString *)saveWaveformImage:(NSImage *)image forTrackUUID:(NSUUID *)uuid;
+ (NSImage *)loadWaveformForPath:(NSString *)path;
+ (void)removeWaveformForPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
