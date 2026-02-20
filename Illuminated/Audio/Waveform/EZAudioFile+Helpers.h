//
//  EZAudioFile+BFTask.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.02.2026.
//

#import <Cocoa/Cocoa.h>
#import "BFTask.h"
#import "EZAudio.h"

NS_ASSUME_NONNULL_BEGIN

@class EZAudioFloatData;

@interface EZAudioFile (Helpers)

- (BFTask<EZAudioFloatData *> *)getWaveformDataWithNumberOfPointsTask:(UInt32)numberOfPoints;

@end

NS_ASSUME_NONNULL_END
