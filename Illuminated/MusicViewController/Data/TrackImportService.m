//
//  TrackImportService.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "TrackImportService.h"
#import "Album.h"
#import "Artist.h"
#import "CoreDataStore.h"
#import "Track.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "BookmarkResolver.h"
#import "MetadataExtractor.h"
#import "NSDictionary+Merge.h"

@interface TrackImportService ()
@property(strong, nonatomic) MetadataExtractor *metadataExtractor;
@end

@implementation TrackImportService

- (instancetype)init
{
  self = [super init];
  if (self) {
    _metadataExtractor = [[MetadataExtractor alloc] init];
  }
  return self;
}

- (BFTask<Track *> *)importAudioFileAtURL:(NSURL *)fileURL {
  NSError *error = nil;
  NSData *bookmark = [BookmarkResolver bookmarkForURL:fileURL error:&error];
  if (error) {
    return [BFTask taskWithError:error];
  }
  
  // clang-format off
  return [[[self extractMetadataFromAudioURL:fileURL] continueWithSuccessBlock:^id(BFTask<NSDictionary *> *task) {
    return [self saveTrackWithMetadata:task.result bookmark:bookmark fileURL:fileURL];
  }] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask<Track *> *task) {
    return [[CoreDataStore reader] fetchObjectWithID:task.result.objectID];
  }];
  // clang-format on
}

#pragma mark - Metadata Extraction

- (BFTask<NSDictionary *> *)extractMetadataFromAudioURL:(NSURL *)audioURL {
  AVURLAsset *asset = [AVURLAsset URLAssetWithURL:audioURL options:nil];
  NSArray *keys = @[@"commonMetadata", @"availableMetadataFormats", @"duration", @"tracks"];
  
  return [[[self loadAssetWithKeys:keys asset:asset]
    continueWithSuccessBlock:^id(BFTask<AVURLAsset *> *task) {
      return [self extractAllMetadataFromAsset:task.result];
    }]
    continueWithSuccessBlock:^id(BFTask<NSDictionary *> *task) {
      return [BFTask taskWithResult:[self.metadataExtractor applyFilenameFallback:task.result
                                                                         audioURL:audioURL]];
    }];
}

- (BFTask<NSDictionary *> *)extractAllMetadataFromAsset:(AVURLAsset *)asset {
  NSMutableDictionary *basicMetadata = [NSMutableDictionary dictionary];
  
  if (CMTIME_IS_VALID(asset.duration)) {
    basicMetadata[@"duration"] = @(CMTimeGetSeconds(asset.duration));
  }
  
  NSDictionary *commonMetadata = [self.metadataExtractor extractFromItems:asset.commonMetadata];
  [basicMetadata addEntriesFromDictionary:commonMetadata];
  
  // clang-format off
  return [[[self loadAudioTrackFromAsset:asset] continueWithSuccessBlock:^id(BFTask<AVAssetTrack *> *task) {
      NSDictionary *audioFormat = [self.metadataExtractor extractAudioFormatFromAudioTrack:task.result];
      return [BFTask taskWithResult:[basicMetadata dictionaryByMergingWithDictionary:audioFormat]];
    }] continueWithSuccessBlock:^id(BFTask<NSDictionary *> *task) {
      return [[self loadFormatSpecificMetadataFromAsset:asset] continueWithSuccessBlock:^id(BFTask<NSDictionary *> *formatTask) {
          return [BFTask taskWithResult:[task.result dictionaryByMergingWithDictionary:formatTask.result]];
        }];
    }];
  // clang-format on
}

- (BFTask<NSDictionary *> *)loadFormatSpecificMetadataFromAsset:(AVURLAsset *)asset {
  NSArray<AVMetadataFormat> *formats = asset.availableMetadataFormats;
  
  if (formats.count == 0) {
    return [BFTask taskWithResult:@{}];
  }
  
  NSMutableArray<BFTask *> *tasks = [NSMutableArray array];
  for (AVMetadataFormat format in formats) {
    [tasks addObject:[self loadMetadataForFormat:format asset:asset]];
  }
  
  return [[BFTask taskForCompletionOfAllTasks:tasks]
    continueWithSuccessBlock:^id(BFTask *_) {
      NSMutableArray *allItems = [NSMutableArray array];
      for (BFTask<NSArray *> *task in tasks) {
        if (task.result) {
          [allItems addObjectsFromArray:task.result];
        }
      }
      return [BFTask taskWithResult:[self.metadataExtractor extractFromItems:allItems]];
    }];
}

#pragma mark - Core Data Saving

- (BFTask<Track *> *)saveTrackWithMetadata:(NSDictionary *)metadata
                                  bookmark:(NSData *)bookmark
                                   fileURL:(NSURL *)fileURL {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Artist *artist = [self findOrCreateArtist:metadata[@"artist"] inContext:context];
    Album *album = [self findOrCreateAlbum:metadata[@"album"] artist:artist inContext:context];

    Track *track = [context firstObjectForEntityName:EntityNameTrack
                                           predicate:[NSPredicate predicateWithFormat:@"fileURL == %@", [fileURL path]]];
    if (!track) {
      track = [context insertNewObjectForEntityName:EntityNameTrack];
      track.uniqueID = [NSUUID new];
      track.title = metadata[@"title"] ?: [fileURL lastPathComponent];
      track.trackNumber = [metadata[@"trackNumber"] intValue];
      track.fileType = [fileURL pathExtension];
      track.bitrate = [metadata[@"bitrate"] intValue];
      track.sampleRate = [metadata[@"sampleRate"] intValue];
      track.duration = [metadata[@"duration"] doubleValue];
      track.fileURL = [fileURL path];
      track.urlBookmark = bookmark;
    }
    return track;
  }];
}

- (Artist *)findOrCreateArtist:(NSString *)artistName inContext:(NSManagedObjectContext *)context {
  if (!artistName) return nil;
  
  Artist *artist = [context firstObjectForEntityName:EntityNameArtist
                                           predicate:[NSPredicate predicateWithFormat:@"name == %@", artistName]];
  if (!artist) {
    artist = [context insertNewObjectForEntityName:EntityNameArtist];
    artist.uniqueID = [NSUUID new];
    artist.name = artistName;
  }
  return artist;
}

- (Album *)findOrCreateAlbum:(NSString *)albumName
                      artist:(Artist *)artist
                   inContext:(NSManagedObjectContext *)context {
  if (!albumName) return nil;
  
  NSPredicate *predicate;
  if (artist) {
    predicate = [NSPredicate predicateWithFormat:@"title == %@ AND artist == %@", albumName, artist];
  } else {
    predicate = [NSPredicate predicateWithFormat:@"title == %@", albumName];
  }
  
  Album *album = [context firstObjectForEntityName:EntityNameAlbum predicate:predicate];
  if (!album) {
    album = [context insertNewObjectForEntityName:EntityNameAlbum];
    album.uniqueID = [NSUUID new];
    album.title = albumName;
    album.artist = artist;
  }
  return album;
}

#pragma mark - Async Wrappers

- (BFTask<AVURLAsset *> *)loadAssetWithKeys:(NSArray *)keys asset:(AVURLAsset *)asset {
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
  
  [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
    NSError *error = nil;
    for (NSString *key in keys) {
      if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
        [source setError:error];
        return;
      }
    }
    [source setResult:asset];
  }];
  
  return source.task;
}

- (BFTask<AVAssetTrack *> *)loadAudioTrackFromAsset:(AVURLAsset *)asset {
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
  
  [asset loadTracksWithMediaType:AVMediaTypeAudio completionHandler:^(NSArray<AVAssetTrack *> *tracks, NSError *error) {
    if (error) {
      [source setError:error];
    } else if (tracks.firstObject) {
      [source setResult:tracks.firstObject];
    } else {
      [source setError:[NSError errorWithDomain:@"ImportError"
                                           code:-1
                                       userInfo:@{NSLocalizedDescriptionKey: @"No audio track found"}]];
    }
  }];
  
  return source.task;
}

- (BFTask<NSArray<AVMetadataItem *> *> *)loadMetadataForFormat:(AVMetadataFormat)format
                                                          asset:(AVURLAsset *)asset {
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
  
  [asset loadMetadataForFormat:format completionHandler:^(NSArray<AVMetadataItem *> *items, NSError *error) {
    NSLog(@"Error loading metadata: %@", error.localizedDescription);
    [source setResult:items ?: @[]];
  }];
  
  return source.task;
}

@end
