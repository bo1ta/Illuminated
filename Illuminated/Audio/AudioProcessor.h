//
//  AudioProcessor.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * AudioProcessor handles real-time audio analysis and feature extraction.
 * Thread-safe for concurrent audio updates and data reads.
 */
@interface AudioProcessor : NSObject

/**
 * The current smoothed RMS amplitude (0.0 to 1.0+)
 */
@property(nonatomic, readonly) float amplitude;

/**
 * The raw audio samples from the most recent update
 */
@property(nonatomic, readonly) const float *audioSamples;

/**
 * The number of audio samples in the buffer
 */
@property(nonatomic, readonly) NSUInteger sampleCount;

/**
 * Initializes the processor with a specific buffer size
 * @param bufferSize Number of audio samples to store (typically 512, 1024, or 2048)
 */
- (instancetype)initWithBufferSize:(NSUInteger)bufferSize NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Updates the processor with new audio data
 * @param data Pointer to audio samples (typically -1.0 to 1.0 range)
 * @param length Number of samples in the data array
 */
- (void)updateWithAudioData:(const float *)data length:(NSUInteger)length;

/**
 * Copies the current audio samples to the provided buffer
 * @param buffer Destination buffer (must be at least sampleCount * sizeof(float) bytes)
 * @param outLength Optional pointer to receive the actual number of samples copied
 * @return YES if successful, NO if buffer is invalid
 */
- (BOOL)copySamplesToBuffer:(float *)buffer length:(nullable NSUInteger *)outLength;

/**
 * Resets all audio state to zero
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
