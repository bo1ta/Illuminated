//
//  ArtworkManager.m
//  Illuminated
//
//  Created by Alexandru Solomon on 25.01.2026.
//

#import <Foundation/Foundation.h>
#import "ArtworkManager.h"

NSString *const kArtworkDirectoryPath = @"Illuminated/Artwork";

@implementation ArtworkManager

+ (NSString *)artworkDirectory {
  static NSString *artworkDir = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = [paths firstObject];
    artworkDir = [appSupport stringByAppendingPathComponent:kArtworkDirectoryPath];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:artworkDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
  });
  return artworkDir;
}

+ (NSString *)saveArtwork:(NSData *)artworkData forUUID:(NSUUID *)uuid {
  if (!artworkData || !uuid) return nil;
  
  NSString *filename = [NSString stringWithFormat:@"%@.jpg", uuid.UUIDString];
  NSString *filePath = [[self artworkDirectory] stringByAppendingPathComponent:filename];
  
  NSImage *image = [[NSImage alloc] initWithData:artworkData];
  NSData *jpegData = [self jpegDataFromImage:image compressionQuality:0.8];
  
  if ([jpegData writeToFile:filePath atomically:YES]) {
    return filePath;
  }
  
  return nil;
}

+ (NSImage *)loadArtworkAtPath:(NSString *)path {
  if (!path) return nil;
  return [[NSImage alloc] initWithContentsOfFile:path];
}

+ (void)deleteArtworkAtPath:(NSString *)path {
  if (path) {
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  }
}

+ (NSData *)jpegDataFromImage:(NSImage *)image compressionQuality:(CGFloat)quality {
  CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
  NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
  return [imageRep representationUsingType:NSBitmapImageFileTypeJPEG
                                properties:@{NSImageCompressionFactor: @(quality)}];
}

@end
