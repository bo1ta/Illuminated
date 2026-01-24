//
//  BPMAnalyzer.mm
//
//
//  Created by Alexandru Solomon on 24.01.2026.
//
//

#import "BPMAnalyzer.h"
#import "BFExecutor.h"

#include <assert.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <vector>

#define LOWER_BPM 84.0
#define UPPER_BPM 146.0
#define BLOCK 4096
#define INTERVAL 128
#define ARRAY_SIZE(x) (sizeof(x) / sizeof(*(x)))

@implementation BPMAnalyzer

+ (BFTask<NSNumber *> *)analyzeBPMForAssetTrack:(AVAssetTrack *)track {
  return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id {
    if (!track) {
      return @(0);
    }
    
    NSError *error = nil;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:track.asset error:&error];
    if (error) {
      NSLog(@"Error creating asset reader: %@", error);
      return @(0);
    }
    
    NSDictionary *settings = @{
      AVFormatIDKey : @(kAudioFormatLinearPCM),
      AVLinearPCMBitDepthKey : @32,
      AVLinearPCMIsFloatKey : @YES,
      AVLinearPCMIsBigEndianKey : @NO,
      AVLinearPCMIsNonInterleaved : @NO,
      AVNumberOfChannelsKey : @1,
      AVSampleRateKey : @44100.0
    };
    
    AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track
                                                                                  outputSettings:settings];
    if (![reader canAddOutput:output]) {
      return @(0);
    }
    [reader addOutput:output];
    
    // Analyze middle 30 seconds
    CMTime duration = track.asset.duration;
    Float64 seconds = CMTimeGetSeconds(duration);
    CMTime startTime = kCMTimeZero;
    CMTime readDuration = duration;
    
    if (seconds > 40.0) {
      Float64 startSeconds = (seconds / 2.0) - 15.0;
      startTime = CMTimeMakeWithSeconds(startSeconds, duration.timescale);
      readDuration = CMTimeMakeWithSeconds(30.0, duration.timescale);
    }
    
    reader.timeRange = CMTimeRangeMake(startTime, readDuration);
    
    if (![reader startReading]) {
      return @(0);
    }
    
    NSMutableData *floatData = [NSMutableData data];
    
    while (reader.status == AVAssetReaderStatusReading) {
      CMSampleBufferRef buffer = [output copyNextSampleBuffer];
      if (buffer) {
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(buffer);
        size_t length = CMBlockBufferGetDataLength(blockBuffer);
        char *dataPointer = NULL;
        if (CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, NULL, &dataPointer) == kCMBlockBufferNoErr) {
          [floatData appendBytes:dataPointer length:length];
        }
        CFRelease(buffer);
      } else {
        break;
      }
    }
    
    if (reader.status == AVAssetReaderStatusCompleted) {
      float *samples = (float *)floatData.bytes;
      NSUInteger frameCount = floatData.length / sizeof(float);
      return [BPMAnalyzer analyzeBPMFromBuffer:samples frames:frameCount sampleRate:44100.0];
    }
    
    return @(0);
  }];
}

+ (BFTask<NSNumber *> *)analyzeBPMFromBuffer:(float *)buffer frames:(NSUInteger)frames sampleRate:(float)sampleRate {
  std::vector<float> data(buffer, buffer + frames);

  return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id {
    if (frames == 0 || sampleRate <= 0) {
      return @(0.0);
    }
    
    double bpm = [self internalAnalyzeBPM:data sampleRate:sampleRate];
    NSLog(@"BPM IS: %f", bpm);
    return @(bpm);
  }];
}

#pragma mark - Internal C-Ported Logic
// https://www.pogo.org.uk/~mark/bpm-tools/

+ (double)internalAnalyzeBPM:(const std::vector<float> &)data sampleRate:(double)rate {
  std::vector<float> nrg;
  nrg.reserve(data.size() / INTERVAL);

  double v = 0.0;
  size_t n = 0;
  size_t len = 0;

  for (float z : data) {
    z = fabsf(z);
    if (z > v) {
      v += (z - v) / 8.0;
    } else {
      v -= (v - z) / 512.0;
    }

    n++;
    if (n == INTERVAL) {
      nrg.push_back(v);
      len++;
      n = 0;
    }
  }

  if (nrg.empty()) {
    return 0.0;
  }

  double bpm = [self scanForBPM:nrg min:LOWER_BPM max:UPPER_BPM sampleRate:rate];
  return bpm;
}

+ (double)scanForBPM:(const std::vector<float> &)nrg min:(double)slowest max:(double)fastest sampleRate:(double)rate {
  auto bpm_to_interval = [&](double bpm) -> double {
    double beats_per_second = bpm / 60.0;
    double samples_per_beat = rate / beats_per_second;
    return samples_per_beat / INTERVAL;
  };

  auto interval_to_bpm = [&](double interval) -> double {
    double samples_per_beat = interval * INTERVAL;
    double beats_per_second = rate / samples_per_beat;
    return beats_per_second * 60.0;
  };

  double slowest_interval = bpm_to_interval(slowest);
  double fastest_interval = bpm_to_interval(fastest);

  unsigned int steps = 1024;
  unsigned int samples = 1024;

  double step = (slowest_interval - fastest_interval) / steps;
  double height = INFINITY;
  double trough = NAN;

  for (double interval = fastest_interval; interval <= slowest_interval; interval += step) {
    double t = 0.0;
    for (unsigned int s = 0; s < samples; s++) {
      t += [self autodifference:nrg interval:interval];
    }

    if (t < height) {
      trough = interval;
      height = t;
    }
  }

  return interval_to_bpm(trough);
}

+ (double)sample:(const std::vector<float> &)nrg offset:(double)offset {
  double n = floor(offset);
  size_t i = (size_t)n;

  if (n >= 0.0 && n < (double)nrg.size()) {
    return nrg[i];
  }
  return 0.0;
}

+ (double)autodifference:(const std::vector<float> &)nrg interval:(double)interval {
  double mid, v, diff, total;
  static const double beats[] = {-32, -16, -8, -4, -2, -1, 1, 2, 4, 8, 16, 32};
  static const double nobeats[] = {-0.5, -0.25, 0.25, 0.5};

  mid = drand48() * nrg.size();
  v = [self sample:nrg offset:mid];

  diff = 0.0;
  total = 0.0;

  for (double beat : beats) {
    double y = [self sample:nrg offset:mid + beat * interval];
    double w = 1.0 / fabs(beat);
    diff += w * fabs(y - v);
    total += w;
  }

  for (double nobeat : nobeats) {
    double y = [self sample:nrg offset:mid + nobeat * interval];
    double w = fabs(nobeat);
    diff -= w * fabs(y - v);
    total += w;
  }

  return diff / total;
}

@end
