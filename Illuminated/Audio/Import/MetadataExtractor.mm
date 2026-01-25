//
//  MetadataExtractor.m
//  Illuminated
//
//  Created by Alexandru Solomon on 25.01.2026.
//

#import <Foundation/Foundation.h>
#import <fileref.h>
#import <tag.h>
#import <tpropertymap.h>
#import <audioproperties.h>
#import "MetadataExtractor.h"

@implementation MetadataExtractor
+ (NSDictionary *)extractMetadataFromFileAtURL:(NSURL *)fileURL {
  NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
  
  const char *filePath = [[fileURL path] UTF8String];
  
  TagLib::FileRef file(filePath);
  
  if (file.isNull() || !file.tag()) {
    NSLog(@"TagLib: Failed to read file or no tags found");
    return @{};
  }
  
  TagLib::Tag *tag = file.tag();
  TagLib::AudioProperties *properties = file.audioProperties();
  
  // Extract basic metadata
  if (!tag->title().isEmpty()) {
    metadata[@"title"] = [NSString stringWithUTF8String:tag->title().toCString(true)];
  }
  
  if (!tag->artist().isEmpty()) {
    metadata[@"artist"] = [NSString stringWithUTF8String:tag->artist().toCString(true)];
  }
  
  if (!tag->album().isEmpty()) {
    metadata[@"album"] = [NSString stringWithUTF8String:tag->album().toCString(true)];
  }
  
  if (!tag->genre().isEmpty()) {
    metadata[@"genre"] = [NSString stringWithUTF8String:tag->genre().toCString(true)];
  }
  
  if (tag->year() > 0) {
    metadata[@"year"] = @(tag->year());
  }
  
  if (tag->track() > 0) {
    metadata[@"trackNumber"] = @(tag->track());
  }
  
  if (properties) {
    metadata[@"duration"] = @(properties->lengthInSeconds());
    metadata[@"bitrate"] = @(properties->bitrate());
    metadata[@"sampleRate"] = @(properties->sampleRate());
  }
  
  NSLog(@"TagLib extracted - Title: %@, Artist: %@, Album: %@",
        metadata[@"title"], metadata[@"artist"], metadata[@"album"]);
  
  return [self applyFilenameFallback:[metadata copy] audioURL:fileURL];
}

+ (NSDictionary *)applyFilenameFallback:(NSDictionary *)metadata audioURL:(NSURL *)audioURL {
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
