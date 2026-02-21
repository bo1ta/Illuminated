//
//  BPMAnalyzer.h
//
//
//  Created by Alexandru Solomon on 24.01.2026.
//
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BFTask<__covariant ResultType>;

@interface BPMAnalyzer : NSObject

+ (BFTask<NSNumber *> *)analyzeBPMForAssetTrack:(AVAssetTrack *)track;

@end

NS_ASSUME_NONNULL_END
