//
//  TrackService.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "TrackService.h"
#import "Album.h"
#import "AlbumDataStore.h"
#import "Artist.h"
#import "ArtistDataStore.h"
#import "ArtworkManager.h"
#import "BPMAnalyzer.h"
#import "BookmarkResolver.h"
#import "CoreDataStore.h"
#import "MetadataExtractor.h"
#import "Track.h"
#import "TrackDataStore.h"
#import "WaveformCacheManager.h"
#import "WaveformGenerator.h"
#import <AVFoundation/AVFoundation.h>

@implementation TrackService

+ (BFTask<Track *> *)findOrInsertByURL:(nonnull NSURL *)url playlist:(nullable Playlist *)playlist {
  return [[TrackDataStore trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      return task;
    }
    return [TrackService importAudioFileAtURL:url playlist:playlist];
  }];
}

+ (BFTask<Track *> *)findOrInsertByURL:(NSURL *)url bookmarkData:(NSData *)bookmarkData {
  return [[TrackDataStore trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      if (![track.urlBookmark isEqualToData:bookmarkData]) {
        return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
          Track *writeTrack = [context objectWithID:track.objectID];
          writeTrack.urlBookmark = bookmarkData;
          return writeTrack;
        }];
      }
      return task;
    }
    return [self importAudioFileAtURL:url bookmarkData:bookmarkData];
  }];
}

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
  return [[self saveTrackWithMetadata:metadata bookmark:bookmark fileURL:fileURL
                             playlist:playlist] continueOnMainThreadWithBlock:^id(BFTask<Track *> *task) {
    if (task.result) {
      return [[CoreDataStore reader] fetchObjectWithID:task.result.objectID];
    }
    return task;
  }];
}

+ (BFTask *)importAudioFileAtURL:(NSURL *)fileURL bookmarkData:(NSData *)bookmarkData {
  NSDictionary *metadata = [MetadataExtractor extractMetadataFromFileAtURL:fileURL];
  return [[self saveTrackWithMetadata:metadata bookmark:bookmarkData fileURL:fileURL
                             playlist:nil] continueOnMainThreadWithBlock:^id(BFTask<Track *> *task) {
    if (task.result) {
      return [[CoreDataStore reader] fetchObjectWithID:task.result.objectID];
    }
    return task;
  }];
}

#pragma mark - Core Data Saving

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
      track = [TrackDataStore insertTrackWithTitle:metadata[@"title"] ?: [fileURL lastPathComponent]
                                           fileURL:[fileURL path]
                                       urlBookmark:bookmark
                                       trackNumber:[metadata[@"trackNumber"] intValue]
                                          fileType:[fileURL pathExtension]
                                           bitrate:[metadata[@"bitrate"] intValue]
                                        sampleRate:[metadata[@"sampleRate"] intValue]
                                          duration:[metadata[@"duration"] doubleValue]
                                               bpm:[metadata[@"bpm"] floatValue]
                                            artist:artist
                                             album:album
                                         inContext:context];
      if (playlist) {
        [track addPlaylistsObject:playlist];
      }
    }
    return track;
  }];
}

+ (Artist *)findOrCreateArtist:(NSString *)artistName inContext:(NSManagedObjectContext *)context {
  if (!artistName) {
    return nil;
  }
  return [ArtistDataStore findOrCreateArtistWithName:artistName inContext:context];
}

+ (Album *)findOrCreateAlbum:(NSString *)albumName
                      artist:(Artist *)artist
                     artwork:(NSData *)artworkData
                   inContext:(NSManagedObjectContext *)context {
  if (!albumName) {
    return nil;
  }

  Album *album = [AlbumDataStore findOrCreateAlbumWithName:albumName artist:artist inContext:context];
  if (!album.artworkPath) {
    album.artworkPath = [ArtworkManager saveArtwork:artworkData forUUID:album.uniqueID];
  }

  return album;
}

+ (BFTask<NSImage *> *)getWaveformForTrack:(Track *)track resolvedURL:(NSURL *)resolvedURL size:(CGSize)size {
  if (track.waveformPath) {
    NSImage *cachedImage = [WaveformCacheManager loadWaveformForPath:track.waveformPath];
    if (cachedImage) {
      return [BFTask taskWithResult:cachedImage];
    }
  }
  return [[WaveformGenerator generateWaveformForTrack:track url:resolvedURL
                                                 size:size] continueWithSuccessBlock:^id(BFTask<NSImage *> *task) {
    NSImage *image = task.result;
    NSString *path = [WaveformCacheManager saveWaveformImage:image forTrackUUID:track.uniqueID];

    if (path) {
      [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
        Track *writeTrack = [context objectWithID:track.objectID];
        if (writeTrack) {
          writeTrack.waveformPath = path;
        }
        return nil;
      }];
    }

    return [BFTask taskWithResult:image];
  }];
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
