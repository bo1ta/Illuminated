//
//  MetadataExtractor.m
//  Illuminated
//
//  Created by Alexandru Solomon on 24.01.2026.
//

#import <Foundation/Foundation.h>
#import "MetadataExtractor.h"
#import <AVFoundation/AVFoundation.h>

@implementation MetadataExtractor

- (NSDictionary *)metadataKeyMap {
  static NSDictionary *keyMap = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    keyMap = @{
      AVMetadataCommonKeyTitle: @"title",
      
      AVMetadataCommonKeyArtist: @"artist",
      AVMetadataIdentifierID3MetadataLeadPerformer: @"artist",
      AVMetadataIdentifieriTunesMetadataArtist: @"artist",
      
      AVMetadataCommonKeyAlbumName: @"album",
      AVMetadataIdentifierID3MetadataAlbumTitle: @"album",
      AVMetadataIdentifieriTunesMetadataAlbum: @"album",
      
      AVMetadataCommonKeyArtwork: @"artwork",
      AVMetadataIdentifierID3MetadataAttachedPicture: @"artwork",
      
      AVMetadataIdentifierID3MetadataTrackNumber: @"trackNumber",
      AVMetadataIdentifieriTunesMetadataTrackNumber: @"trackNumber"
    };
  });
  return keyMap;
}

- (NSDictionary *)extractFromItems:(NSArray<AVMetadataItem *> *)items {
  NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
  
  for (AVMetadataItem *item in items) {
    NSString *keyToCheck = item.commonKey ?: item.identifier;
    NSString *metadataKey = [self metadataKeyMap][keyToCheck];
    
    if (!metadataKey || metadata[metadataKey]) continue; // Skip if already set
    
    id value = [metadataKey isEqualToString:@"artwork"] ? [item dataValue] : [item stringValue];
    if (!value) continue;
    
    if ([metadataKey isEqualToString:@"trackNumber"]) {
      value = @([[value componentsSeparatedByString:@"/"].firstObject integerValue]);
    }
    
    metadata[metadataKey] = value;
  }
  
  return [metadata copy];
}

- (NSDictionary *)extractAudioFormatFromAudioTrack:(AVAssetTrack *)audioTrack {
  NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
  if (audioTrack.estimatedDataRate > 0) {
    metadata[@"bitrate"] = @((NSInteger)(audioTrack.estimatedDataRate / 1000));
  }
  
  NSArray *formatDescriptions = audioTrack.formatDescriptions;
  if (formatDescriptions.count > 0) {
    CMAudioFormatDescriptionRef desc = (__bridge CMAudioFormatDescriptionRef)formatDescriptions[0];
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc);
    if (asbd) {
      metadata[@"sampleRate"] = @((NSInteger)asbd->mSampleRate);
    }
  }
  
  return [metadata copy];
}

- (NSDictionary *)applyFilenameFallback:(NSDictionary *)metadata audioURL:(NSURL *)audioURL {
  NSMutableDictionary *result = [metadata mutableCopy];
  
  NSString *title = result[@"title"];
  NSString *artist = result[@"artist"];
  
  if (title && artist) {
    return result;
  }
  
  NSString *filename = [[audioURL lastPathComponent] stringByDeletingPathExtension];
  
  NSArray *parts = [filename componentsSeparatedByString:@" - "];
  
  if (parts.count >= 2) {
    if (!artist) {
      result[@"artist"] = [parts[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    if (!title) {
      NSArray *titleParts = [parts subarrayWithRange:NSMakeRange(1, parts.count - 1)];
      NSString *fullTitle = [titleParts componentsJoinedByString:@" - "];
      result[@"title"] = [fullTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
  } else {
    if (!title) {
      result[@"title"] = filename;
    }
  }
  
  return result;
}

@end
