//
//  BPMAnalyzer.h
//
//
//  Created by Alexandru Solomon on 24.01.2026.
//
//

#import "BFTask.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BPMAnalyzer : NSObject

+ (BFTask<NSNumber *> *)analyzeBPMForAssetTrack:(AVAssetTrack *)track;

@end

NS_ASSUME_NONNULL_END
