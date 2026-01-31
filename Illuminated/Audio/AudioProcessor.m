//
//  AudioProcessor.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "AudioProcessor.h"
#import <Accelerate/Accelerate.h>
#import <os/lock.h>

#pragma mark - Constants

static const float kDefaultAmplitudeSmoothingFactor = 0.9f;

#pragma mark - Private Interface

@interface AudioProcessor ()

@property(nonatomic, assign) os_unfair_lock lock;

@property(nonatomic, assign) float *audioBuffer;
@property(nonatomic, assign) NSUInteger bufferSize;

@property(nonatomic, assign) float smoothedAmplitude;
@property(nonatomic, assign) float smoothingFactor;

@end

#pragma mark - Implementation

@implementation AudioProcessor
- (instancetype)initWithBufferSize:(NSUInteger)bufferSize {
  self = [super init];
  if (self) {
    if (bufferSize == 0) {
      NSLog(@"AudioProcessor: Invalid buffer size (0)");
      return nil;
    }

    _lock = OS_UNFAIR_LOCK_INIT;
    _bufferSize = bufferSize;
    _smoothedAmplitude = 0.0f;
    _smoothingFactor = kDefaultAmplitudeSmoothingFactor;

    _audioBuffer = (float *)calloc(_bufferSize, sizeof(float));
    if (!_audioBuffer) {
      NSLog(@"AudioProcessor: Failed to allocate audio buffer");
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  if (_audioBuffer) {
    free(_audioBuffer);
    _audioBuffer = NULL;
  }
}

#pragma mark - Properties

- (float)amplitude {
  os_unfair_lock_lock(&_lock);
  float value = _smoothedAmplitude;
  os_unfair_lock_unlock(&_lock);
  return value;
}

- (const float *)audioSamples {
  return _audioBuffer;
}

- (NSUInteger)sampleCount {
  return _bufferSize;
}

#pragma mark - Audio Processing

- (void)updateWithAudioData:(const float *)data length:(NSUInteger)length {
  if (!data || length == 0) {
    return;
  }

  os_unfair_lock_lock(&_lock);

  NSUInteger copyLength = MIN(length, _bufferSize);
  memcpy(_audioBuffer, data, copyLength * sizeof(float));

  if (copyLength < _bufferSize) {
    memset(_audioBuffer + copyLength, 0, (_bufferSize - copyLength) * sizeof(float));
  }

  float rms = [self calculateRMSForSamples:_audioBuffer length:copyLength];

  _smoothedAmplitude = _smoothedAmplitude * _smoothingFactor + rms * (1.0f - _smoothingFactor);

  os_unfair_lock_unlock(&_lock);
}

- (float)calculateRMSForSamples:(const float *)samples length:(NSUInteger)length {
  if (length == 0) {
    return 0.0f;
  }

  float meanSquare = 0.0f;
  vDSP_measqv(samples, 1, &meanSquare, length);
  return sqrtf(meanSquare);
}

- (BOOL)copySamplesToBuffer:(float *)buffer length:(NSUInteger *)outLength {
  if (!buffer) {
    return NO;
  }

  os_unfair_lock_lock(&_lock);
  memcpy(buffer, _audioBuffer, _bufferSize * sizeof(float));
  if (outLength) {
    *outLength = _bufferSize;
  }
  os_unfair_lock_unlock(&_lock);

  return YES;
}

- (void)reset {
  os_unfair_lock_lock(&_lock);
  memset(_audioBuffer, 0, _bufferSize * sizeof(float));
  _smoothedAmplitude = 0.0f;
  os_unfair_lock_unlock(&_lock);
}

@end
