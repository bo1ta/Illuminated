//
//  WaveformCacheManager.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "WaveformCacheManager.h"

@implementation WaveformCacheManager

+ (NSString *)waveformDirectory {
  static NSString *waveformDir = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = [paths firstObject];
    waveformDir = [appSupport stringByAppendingPathComponent:@"Illuminated/Waveforms"];

    [[NSFileManager defaultManager] createDirectoryAtPath:waveformDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
  });
  return waveformDir;
}

+ (NSString *)saveWaveformImage:(NSImage *)image forTrackUUID:(NSUUID *)uuid {
  if (!image || !uuid) return nil;

  NSString *filename = [NSString stringWithFormat:@"%@.png", uuid.UUIDString];
  NSString *filePath = [[self waveformDirectory] stringByAppendingPathComponent:filename];

  CGImageRef cgRef = [image CGImageForProposedRect:NULL context:nil hints:nil];
  NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
  [newRep setSize:[image size]];
  NSData *pngData = [newRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];

  if ([pngData writeToFile:filePath atomically:YES]) {
    return filePath;
  }

  return nil;
}

+ (NSImage *)loadWaveformForPath:(NSString *)path {
  if (!path) return nil;
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) return nil;

  return [[NSImage alloc] initWithContentsOfFile:path];
}

+ (void)removeWaveformForPath:(NSString *)path {
  if (path) {
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  }
}

@end
