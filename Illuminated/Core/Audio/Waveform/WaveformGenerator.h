//
//  WaveformGenerator.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Track;
@class BFTask<__covariant ResultType>;

@interface WaveformGenerator : NSObject

+ (BFTask<NSImage *> *)generateWaveformForTrack:(Track *)track url:(NSURL *)url size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
