//
//  TrackImportService.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "TrackImportService.h"
#import "Album.h"
#import "Artist.h"
#import "ArtworkManager.h"
#import "BPMAnalyzer.h"
#import "BookmarkResolver.h"
#import "BFExecutor.h"
#import "BFTaskCompletionSource.h"
#import "CoreDataStore.h"
#import "MetadataExtractor.h"
#import "Track.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@implementation TrackImportService

+ (BFTask<Track *> *)analyzeBPMForTrackURL:(NSURL *)trackURL {
  AVURLAsset *asset = [AVURLAsset URLAssetWithURL:trackURL options:nil];
  return [[[[self loadAudioTrackFromAsset:asset] continueWithSuccessBlock:^id(BFTask<AVAssetTrack *> *task) {
    return [BPMAnalyzer analyzeBPMForAssetTrack:task.result];
  }] continueWithSuccessBlock:^id(BFTask<NSNumber *> *task) {
    return [self updateBPMForTrackWithFileURL:trackURL bpm:task.result];
  }] continueWithBlock:^id(BFTask *task) {
    if (task.error) {
      NSLog(@"Error analyzing bpm for track: %@", task.error.localizedDescription);
    }

    return task;
  }];
}

+ (BFTask *)importAudioFilesAtURLs:(NSArray<NSURL *> *)filesURLs withPlaylist:(nullable Playlist *)playlist {
  return [[self filterExistingURLs:filesURLs] continueWithSuccessBlock:^id(BFTask *task) {
    NSArray<NSURL *> *urls = task.result;

    NSMutableArray<BFTask *> *tasks = [NSMutableArray array];
    for (NSURL *url in urls) {
      NSError *error = nil;
      NSData *bookmark = [BookmarkResolver bookmarkForURL:url error:&error];
      if (error) {
        [tasks addObject:[BFTask taskWithError:error]];
        continue;
        ;
      }

      NSDictionary *metadata = [MetadataExtractor extractMetadataFromFileAtURL:url];
      [tasks addObject:[self saveTrackWithMetadata:metadata bookmark:bookmark fileURL:url playlist:playlist]];
    }

    return [BFTask taskForCompletionOfAllTasks:tasks];
  }];
}

+ (BFTask<NSArray<NSURL *> *> *)filterExistingURLs:(NSArray<NSURL *> *)urls {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    NSMutableArray<NSURL *> *nonExisting = [NSMutableArray array];

    for (NSURL *url in urls) {
      BOOL exists = [context objectExistsForEntityName:EntityNameTrack
                                             predicate:[NSPredicate predicateWithFormat:@"fileURL == %@", [url path]]];
      if (!exists) {
        [nonExisting addObject:url];
      }
    }

    return [nonExisting copy];
  }];
}

+ (BFTask<Track *> *)importAudioFileAtURL:(NSURL *)fileURL playlist:(nullable Playlist *)playlist {
  NSError *error = nil;
  NSData *bookmark = [BookmarkResolver bookmarkForURL:fileURL error:&error];
  if (error) {
    return [BFTask taskWithError:error];
  }

  NSDictionary *metadata = [MetadataExtractor extractMetadataFromFileAtURL:fileURL];
  return [[self saveTrackWithMetadata:metadata
                             bookmark:bookmark
                              fileURL:fileURL
                             playlist:playlist]
          continueOnMainThreadWithBlock:^id(BFTask<Track *> *task) {
    if (task.result) {
      return [[CoreDataStore reader] fetchObjectWithID:task.result.objectID];
    }
    return task;
  }];
}

+ (BFTask *)importAudioFileAtURL:(NSURL *)fileURL bookmarkData:(NSData *)bookmarkData {
  NSDictionary *metadata = [MetadataExtractor extractMetadataFromFileAtURL:fileURL];
  return [[self saveTrackWithMetadata:metadata
                             bookmark:bookmarkData
                              fileURL:fileURL
                             playlist:nil]
          continueOnMainThreadWithBlock:^id(BFTask<Track *> *task) {
    if (task.result) {
      return [[CoreDataStore reader] fetchObjectWithID:task.result.objectID];
    }
    return task;
  }];
}

#pragma mark - Core Data Saving

+ (BFTask<Track *> *)updateBPMForTrackWithFileURL:(NSURL *)fileURL bpm:(NSNumber *)bpm {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Track *track =
        [context firstObjectForEntityName:EntityNameTrack
                                predicate:[NSPredicate predicateWithFormat:@"fileURL == %@", [fileURL path]]];
    if (track) {
      track.bpm = [bpm floatValue];
      return track;
    }
    return nil;
  }];
}

+ (BFTask<Track *> *)saveTrackWithMetadata:(NSDictionary *)metadata
                                  bookmark:(NSData *)bookmark
                                   fileURL:(NSURL *)fileURL
                                  playlist:(nullable Playlist *)playlist {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Artist *artist = [self findOrCreateArtist:metadata[@"artist"] inContext:context];
    Album *album = [self findOrCreateAlbum:metadata[@"album"]
                                    artist:artist
                                   artwork:metadata[@"artwork"]
                                 inContext:context];

    Track *track =
        [context firstObjectForEntityName:EntityNameTrack
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
      track.bpm = [metadata[@"bpm"] floatValue];
      track.fileURL = [fileURL path];
      track.urlBookmark = bookmark;
      track.artist = artist;
      track.album = album;

      if (playlist) {
        [track addPlaylistsObject:playlist];
      }
    }
    return track;
  }];
}

+ (Artist *)findOrCreateArtist:(NSString *)artistName inContext:(NSManagedObjectContext *)context {
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

+ (Album *)findOrCreateAlbum:(NSString *)albumName
                      artist:(Artist *)artist
                     artwork:(NSData *)artworkData
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

  if (artworkData) {
    NSString *artworkPath = [ArtworkManager saveArtwork:artworkData forUUID:album.uniqueID];
    album.artworkPath = artworkPath;
  }

  return album;
}

#pragma mark - Async Wrappers

+ (BFTask<AVAssetTrack *> *)loadAudioTrackFromAsset:(AVURLAsset *)asset {
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];

  [asset loadTracksWithMediaType:AVMediaTypeAudio
               completionHandler:^(NSArray<AVAssetTrack *> *tracks, NSError *error) {
                 if (error) {
                   [source setError:error];
                 } else if (tracks.firstObject) {
                   [source setResult:tracks.firstObject];
                 } else {
                   [source setError:[NSError errorWithDomain:@"ImportError"
                                                        code:-1
                                                    userInfo:@{NSLocalizedDescriptionKey : @"No audio track found"}]];
                 }
               }];

  return source.task;
}

@end
