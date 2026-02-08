//
//  WaveformGenerator.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "WaveformGenerator.h"
#import "BFExecutor.h"
#import "Track.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

@implementation WaveformGenerator

+ (BFTask<NSImage *> *)generateWaveformForTrack:(Track *)track url:(NSURL *)url size:(CGSize)size {
  return [BFTask
      taskFromExecutor:[BFExecutor defaultExecutor]
             withBlock:^id {
               NSError *error = nil;
               AVAsset *asset = [AVAsset assetWithURL:url];

               if (!asset.isReadable) {
                 return [BFTask
                     taskWithError:[NSError errorWithDomain:@"WaveformGenerator"
                                                       code:-1
                                                   userInfo:@{NSLocalizedDescriptionKey : @"Asset not readable"}]];
               }

               AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
               if (error) {
                 return [BFTask taskWithError:error];
               }

               AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
               if (!audioTrack) {
                 return [BFTask
                     taskWithError:[NSError errorWithDomain:@"WaveformGenerator"
                                                       code:-2
                                                   userInfo:@{NSLocalizedDescriptionKey : @"No audio track found"}]];
               }

               // Determine the optimal output settings
               NSDictionary *outputSettings = [self outputSettingsForTrack:track assetTrack:audioTrack];

               AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack
                                                                                   outputSettings:outputSettings];
               if ([reader canAddOutput:output]) {
                 [reader addOutput:output];
               } else {
                 return [BFTask
                     taskWithError:[NSError
                                       errorWithDomain:@"WaveformGenerator"
                                                  code:-3
                                              userInfo:@{NSLocalizedDescriptionKey : @"Cannot add output to reader"}]];
               }

               if (![reader startReading]) {
                 return [BFTask taskWithError:reader.error];
               }

               return [self processAudioFromOutput:output reader:reader size:size];
             }];
}

+ (NSDictionary *)outputSettingsForTrack:(Track *)track assetTrack:(AVAssetTrack *)assetTrack {
  NSSet *compressedFormats = [NSSet setWithObjects:@"mp3", @"m4a", @"aac", @"m4b", @"m4p", nil];
  if (track.fileType && [compressedFormats containsObject:track.fileType.lowercaseString]) {
    return [self defaultOutputSettings];
  }

  // Inspect the format for valid uncompressed types (WAV, AIFF, FLAC)
  NSArray *formatDescriptions = assetTrack.formatDescriptions;
  if (formatDescriptions.count > 0) {
    CMFormatDescriptionRef formatDescription = (__bridge CMFormatDescriptionRef)formatDescriptions.firstObject;
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);

    // Check for 16-bit, Signed Integer, Native Endian PCM
    if (asbd->mFormatID == kAudioFormatLinearPCM) {
      BOOL isFloat = (asbd->mFormatFlags & kAudioFormatFlagIsFloat);
      BOOL isSigned = (asbd->mFormatFlags & kAudioFormatFlagIsSignedInteger);
      BOOL isBigEndian = (asbd->mFormatFlags & kAudioFormatFlagIsBigEndian);

      if (!isFloat && isSigned && asbd->mBitsPerChannel == 16 && !isBigEndian) {
        return nil;
      }
    }
  }

  return [self defaultOutputSettings];
}

+ (NSDictionary *)defaultOutputSettings {
  return @{
    AVFormatIDKey : @(kAudioFormatLinearPCM),
    AVLinearPCMBitDepthKey : @16,
    AVLinearPCMIsBigEndianKey : @NO,
    AVLinearPCMIsFloatKey : @NO,
    AVLinearPCMIsNonInterleaved : @NO,
    AVNumberOfChannelsKey : @1
  };
}

+ (BFTask<NSImage *> *)processAudioFromOutput:(AVAssetReaderTrackOutput *)output
                                       reader:(AVAssetReader *)reader
                                         size:(CGSize)size {

  AVAssetTrack *track = output.track;
  CMTime duration = track.asset.duration;
  Float64 durationSeconds = CMTimeGetSeconds(duration);
  if (durationSeconds <= 0) durationSeconds = 1;

  CMFormatDescriptionRef formatDesc = (__bridge CMFormatDescriptionRef)track.formatDescriptions.firstObject;
  const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc);

  Float64 sampleRate = asbd->mSampleRate > 0 ? asbd->mSampleRate : 44100.0;

  NSInteger targetPixels = (NSInteger)size.width;
  if (targetPixels <= 0) targetPixels = 100;

  float *pixelData = (float *)calloc(targetPixels, sizeof(float));
  if (!pixelData)
    return [BFTask taskWithError:[NSError errorWithDomain:@"WaveformGenerator"
                                                     code:-4
                                                 userInfo:@{NSLocalizedDescriptionKey : @"Memory allocation failed"}]];

  __block NSInteger currentPixelIndex = 0;
  __block double currentPixelSqSum = 0;
  __block NSInteger samplesInCurrentPixel = 0;

  __block NSInteger samplesPerPixel = 1;
  __block BOOL headerRead = NO;

  CFAbsoluteTime startRead = CFAbsoluteTimeGetCurrent();

  while (reader.status == AVAssetReaderStatusReading) {
    CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
    if (sampleBuffer) {
      CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
      if (!blockBuffer) {
        CFRelease(sampleBuffer);
        continue;
      }

      // On first buffer, finalize our sizing logic
      if (!headerRead) {
        CMFormatDescriptionRef sbufFormat = CMSampleBufferGetFormatDescription(sampleBuffer);
        const AudioStreamBasicDescription *sbufASBD = CMAudioFormatDescriptionGetStreamBasicDescription(sbufFormat);

        UInt32 tempChannels = sbufASBD->mChannelsPerFrame;
        Float64 tempRate = sbufASBD->mSampleRate;
        if (tempRate <= 0) tempRate = sampleRate; // Fallback

        // Total samples = Duration * Rate * Channels
        // This gives us the total number of int16 values we expect to read
        NSInteger estimatedTotalSamples = (NSInteger)(durationSeconds * tempRate * tempChannels);
        if (estimatedTotalSamples <= 0) estimatedTotalSamples = targetPixels * 100;

        samplesPerPixel = estimatedTotalSamples / targetPixels;
        if (samplesPerPixel < 1) samplesPerPixel = 1;

        headerRead = YES;
      }

      size_t length = CMBlockBufferGetDataLength(blockBuffer);
      if (length > 0) {
        char *dataPointer = NULL;
        CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, NULL, &dataPointer);

        int16_t *samples = (int16_t *)dataPointer;
        NSInteger sampleCount = length / sizeof(int16_t);

        for (NSInteger i = 0; i < sampleCount; i++) {
          int16_t val = samples[i];
          float normalized = val / 32768.0f;
          currentPixelSqSum += (normalized * normalized);
          samplesInCurrentPixel++;

          if (samplesInCurrentPixel >= samplesPerPixel) {
            if (currentPixelIndex < targetPixels) {
              pixelData[currentPixelIndex] = sqrtf((float)(currentPixelSqSum / samplesInCurrentPixel));
            }

            currentPixelIndex++;
            currentPixelSqSum = 0;
            samplesInCurrentPixel = 0;

            if (currentPixelIndex >= targetPixels) {
              break;
            }
          }
        }
      }

      CFRelease(sampleBuffer);

      if (currentPixelIndex >= targetPixels) break;
    } else {
      break;
    }
  }

  CFAbsoluteTime endRead = CFAbsoluteTimeGetCurrent();
  NSImage *image = nil;
  if (reader.status == AVAssetReaderStatusCompleted || currentPixelIndex > 0) {
    float maxVal = 0;
    vDSP_maxv(pixelData, 1, &maxVal, targetPixels);
    if (maxVal > 0) {
      float scale = 1.0f / maxVal;
      vDSP_vsmul(pixelData, 1, &scale, pixelData, 1, targetPixels);
    }

    image = [self renderWaveformFromDownsampledData:pixelData count:targetPixels size:size];
  }

  free(pixelData);

  if (image) {
    return [BFTask taskWithResult:image];
  } else {
    return [BFTask taskWithError:reader.error];
  }
}

+ (NSImage *)renderWaveformFromDownsampledData:(float *)downsampledData count:(NSInteger)count size:(CGSize)size {
  NSImage *image = [[NSImage alloc] initWithSize:size];
  [image lockFocus];

  NSBezierPath *path = [NSBezierPath bezierPath];
  CGFloat midY = size.height / 2.0;

  [[[NSColor systemGrayColor] colorWithAlphaComponent:0.5] setFill];

  for (NSInteger i = 0; i < count; i++) {
    CGFloat amplitude = downsampledData[i] * (size.height / 2.0);
    NSRect barRect = NSMakeRect(i, midY - amplitude, 1, amplitude * 2);
    [NSBezierPath fillRect:barRect];
  }

  [image unlockFocus];

  return image;
}

@end
