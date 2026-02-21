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
#import <id3v2tag.h>
#import <id3v2frame.h>
#import <flacfile.h>
#import <flacpicture.h>
#import <xiphcomment.h>
#import <mp4file.h>
#import <mp4tag.h>
#import <mpegfile.h>
#import <attachedpictureframe.h>
#import <mp4coverart.h>

@implementation MetadataExtractor

#pragma mark - Read

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
  
  NSString *extension = [[fileURL pathExtension] lowercaseString];
  NSData *artworkData = nil;
  
  if ([extension isEqualToString:@"mp3"]) {
    artworkData = [self extractArtworkFromMP3:filePath];
  } else if ([extension isEqualToString:@"flac"]) {
    artworkData = [self extractArtworkFromFLAC:filePath];
  } else if ([extension isEqualToString:@"m4a"] || [extension isEqualToString:@"mp4"]) {
    artworkData = [self extractArtworkFromM4A:filePath];
  }
  
  if (artworkData) {
    metadata[@"artwork"] = artworkData;
    NSLog(@"TagLib: Extracted artwork (%lu bytes)", (unsigned long)artworkData.length);
  }
  
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

#pragma mark - Artwork Metadata

+ (NSData *)extractArtworkFromMP3:(const char *)filePath {
  TagLib::MPEG::File mp3File(filePath);
  
  if (!mp3File.isValid() || !mp3File.ID3v2Tag()) {
    return nil;
  }
  
  TagLib::ID3v2::Tag *tag = mp3File.ID3v2Tag();
  TagLib::ID3v2::FrameList frameList = tag->frameList("APIC");
  
  if (frameList.isEmpty()) {
    return nil;
  }
  
  TagLib::ID3v2::AttachedPictureFrame *frame =
    static_cast<TagLib::ID3v2::AttachedPictureFrame *>(frameList.front());
  
  TagLib::ByteVector pictureData = frame->picture();
  
  return [NSData dataWithBytes:pictureData.data() length:pictureData.size()];
}

+ (NSData *)extractArtworkFromFLAC:(const char *)filePath {
  TagLib::FLAC::File flacFile(filePath);
  
  if (!flacFile.isValid()) {
    return nil;
  }
  
  const TagLib::List<TagLib::FLAC::Picture *> &picList = flacFile.pictureList();
  
  if (picList.isEmpty()) {
    return nil;
  }
  
  TagLib::FLAC::Picture *picture = picList.front();
  TagLib::ByteVector pictureData = picture->data();
  
  return [NSData dataWithBytes:pictureData.data() length:pictureData.size()];
}

+ (NSData *)extractArtworkFromM4A:(const char *)filePath {
  TagLib::MP4::File mp4File(filePath);
  
  if (!mp4File.isValid() || !mp4File.tag()) {
    return nil;
  }
  
  TagLib::MP4::Tag *tag = mp4File.tag();
  
  if (!tag->contains("covr")) {
    return nil;
  }
  
  TagLib::MP4::CoverArtList coverList = tag->item("covr").toCoverArtList();
  
  if (coverList.isEmpty()) {
    return nil;
  }
  
  TagLib::MP4::CoverArt coverArt = coverList.front();
  TagLib::ByteVector pictureData = coverArt.data();
  
  return [NSData dataWithBytes:pictureData.data() length:pictureData.size()];
}

#pragma mark - Write

+ (void)updateMetadataAtURL:(NSURL *)fileURL metadata:(NSDictionary *)metadata {
  const char *filePath = [[fileURL path] UTF8String];
  TagLib::FileRef file(filePath);
  
  if (file.isNull() || !file.tag()) {
    NSLog(@"TagLib: Failed to read file or no tags found");
    return;
  }
  
  TagLib::Tag *tag = file.tag();
  
  NSString *title = metadata[@"title"];
  if (title) {
    tag->setTitle([title UTF8String]);
  }
  
  NSString *artist = metadata[@"artist"];
  if (artist) {
    tag->setArtist([artist UTF8String]);
  }

  NSString *album = metadata[@"album"];
  if (album) {
    tag->setAlbum([album UTF8String]);
  }
  
  NSString *genre = metadata[@"genre"];
  if (genre) {
    tag->setGenre([genre UTF8String]);
  }
  
  NSNumber *year = metadata[@"year"];
  if (year) {
    tag->setYear([year intValue]);
  }
  
  bool success = file.save();
  if (!success) {
    NSLog(@"TagLib: Failed to save metadata to file");
  }
}

@end
