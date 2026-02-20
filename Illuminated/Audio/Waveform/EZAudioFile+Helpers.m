//
//  EZAudioFile+Helpers.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.02.2026.
//

#import "EZAudioFile+Helpers.h"
#import "BFExecutor.h"
#import "BFTaskCompletionSource.h"

@implementation EZAudioFile (Helpers)
- (BFTask<EZAudioFloatData *> *)getWaveformDataWithNumberOfPointsTask:(UInt32)numberOfPoints {
  return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
    BFTaskCompletionSource<EZAudioFloatData *> *completionSource = [BFTaskCompletionSource taskCompletionSource];
    
    [self getWaveformDataWithNumberOfPoints:numberOfPoints completion:^(float **waveformData, int length) {
      [completionSource setResult:[EZAudioFloatData dataWithNumberOfChannels:2 buffers:waveformData bufferSize:length]];
    }];
    
    return [completionSource task];
  }];
}
@end
