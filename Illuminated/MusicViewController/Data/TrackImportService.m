//
//  TrackImportService.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "TrackImportService.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@implementation TrackImportService

- (BFTask<Track *> *)importAudioFileAtURL:(NSURL *)fileURL {
  return [[[[self extractMetadataFromAudioURL:fileURL]
      continueWithSuccessBlock:^id _Nullable(BFTask<NSDictionary *> *_Nonnull task) {
        NSDictionary *metadata = task.result;

        NSString *title = metadata[@"title"] ?: [fileURL lastPathComponent];
        NSString *artistName = metadata[@"artist"];
        NSString *albumName = metadata[@"album"];
        NSNumber *trackNumber = metadata[@"trackNumber"];
        NSNumber *year = metadata[@"year"];
        NSString *genre = metadata[@"genre"];
        NSData *artworkData = metadata[@"artwork"];
        NSNumber *duration = metadata[@"duration"];
        NSNumber *bitrate = metadata[@"bitrate"];
        NSNumber *sampleRate = metadata[@"sampleRate"];

        return [[CoreDataStore writeOnlyStore]
            performWrite:^id _Nullable(NSManagedObjectContext *_Nonnull context,
                                       NSError *_Nullable __autoreleasing *_Nullable error) {
              Artist *artist = nil;
              if (artistName) {
                artist = [context firstObjectForEntityName:EntityNameArtist
                                                 predicate:[NSPredicate predicateWithFormat:@"name == %@", artistName]];
                if (!artist) {
                  artist = [context insertNewObjectForEntityName:EntityNameArtist];
                  [artist setUniqueID:[NSUUID new]];
                  [artist setName:artistName];
                }
              }

              Album *album = nil;
              if (albumName) {
                album = [context firstObjectForEntityName:EntityNameAlbum
                                                predicate:[NSPredicate predicateWithFormat:@"title == %@", artistName]];
                if (!album) {
                  album = [context insertNewObjectForEntityName:EntityNameAlbum];
                  album.uniqueID = [NSUUID new];
                  album.title = albumName;
                  album.artist = artist;
                }
              }

              Track *track = [context firstObjectForEntityName:EntityNameTrack
                                                     predicate:[NSPredicate predicateWithFormat:@"title == %@", title]];
              if (!track) {
                track = [context insertNewObjectForEntityName:EntityNameTrack];
                track.uniqueID = [NSUUID new];
                track.title = title;
                track.trackNumber = [trackNumber intValue] ?: 0;
                track.fileType = [fileURL pathExtension];
                track.bitrate = [bitrate intValue] ?: 0;
                track.sampleRate = [sampleRate intValue] ?: 0;
                track.duration = [duration doubleValue] ?: 0.0;
                track.fileURL = [fileURL path];

                /// Create security-scaped bookmark (for playback)
                NSData *bookmark = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                                     includingResourceValuesForKeys:nil
                                                      relativeToURL:nil
                                                              error:error];
                if (bookmark) {
                  track.urlBookmark = bookmark;
                } else {
                  NSLog(@"Critical: Could not create security bookmark");
                }
              }

              return track;
            }];
      }] continueWithBlock:^id _Nullable(BFTask *_Nonnull task) {
    if (task.error) {
      NSLog(@"Error importing track: %@", task.error);
    }

    return task;
  }] continueWithExecutor:[BFExecutor mainThreadExecutor]
                withBlock:^id _Nullable(BFTask<Track *> *_Nonnull task) {
                  NSManagedObjectID *objectID = task.result.objectID;
                  if (objectID) {
                    return [[CoreDataStore readOnlyStore] fetchObjectWithID:objectID];
                  }
                  return task;
                }];
}

- (BFTask<NSDictionary *> *)extractMetadataFromAudioURL:(NSURL *)audioURL {
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];

  // 1. Use AVURLAsset for better control
  AVURLAsset *asset = [AVURLAsset URLAssetWithURL:audioURL options:nil];

  // 2. Load BOTH commonMetadata and the general metadata (for ID3/Track info)
  NSArray *keys = @[ @"commonMetadata", @"metadata", @"duration" ];

  // Capture asset strongly to prevent deallocation
  [asset loadValuesAsynchronouslyForKeys:keys
                       completionHandler:^{
                         @try {
                           // Check status of ALL keys
                           for (NSString *key in keys) {
                             NSError *error = nil;
                             if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                               [source setError:error];
                               return;
                             }
                           }

                           NSMutableDictionary *metadata = [NSMutableDictionary dictionary];

                           // Safe Duration
                           if (CMTIME_IS_VALID(asset.duration)) {
                             metadata[@"duration"] = @(CMTimeGetSeconds(asset.duration));
                           }

                           // Use the loaded metadata arrays directly
                           NSArray *allMetadata = asset.metadata;
                           NSArray *commonMetadata = asset.commonMetadata;

                           // Process Common
                           for (AVMetadataItem *item in commonMetadata) {
                             NSString *key = [item commonKey];
                             id value = [item value]; // Use 'value' instead of 'stringValue' for safety

                             if (!key || !value)
                               continue;

                             if ([key isEqualToString:AVMetadataCommonKeyTitle])
                               metadata[@"title"] = [item stringValue];
                             else if ([key isEqualToString:AVMetadataCommonKeyArtist])
                               metadata[@"artist"] = [item stringValue];
                             else if ([key isEqualToString:AVMetadataCommonKeyAlbumName])
                               metadata[@"album"] = [item stringValue];
                             else if ([key isEqualToString:AVMetadataCommonKeyArtwork])
                               metadata[@"artwork"] = [item dataValue];
                           }

                           // Process ID3/Track Number safely from the already loaded 'allMetadata'
                           NSArray *trackItems =
                               [AVMetadataItem metadataItemsFromArray:allMetadata
                                                              withKey:AVMetadataID3MetadataKeyTrackNumber
                                                             keySpace:AVMetadataKeySpaceID3];
                           if (trackItems.count > 0) {
                             NSString *trackString = [trackItems.firstObject stringValue];
                             if (trackString) {
                               metadata[@"trackNumber"] =
                                   @([[trackString componentsSeparatedByString:@"/"].firstObject integerValue]);
                             }
                           }

                           NSLog(@"DEBUG: Successfully parsed all metadata. Setting result.");
                           [source setResult:[metadata copy]];

                         } @catch (NSException *e) {
                           NSLog(@"DEBUG: Caught exception: %@", e);
                           [source setError:[NSError errorWithDomain:@"ImportError"
                                                                code:-1
                                                            userInfo:@{NSLocalizedDescriptionKey : e.reason}]];
                         }
                       }];

  return source.task;
}

@end
