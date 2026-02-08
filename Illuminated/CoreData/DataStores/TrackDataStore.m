//
//  TrackDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "TrackDataStore.h"
#import "CoreDataStore.h"
#import "Playlist.h"
#import "Track.h"
#import "TrackImportService.h"
#import <Foundation/Foundation.h>

@implementation TrackDataStore

+ (BFTask<Track *> *)trackWithURL:(NSURL *)url {
  return [[CoreDataStore reader] firstObjectForEntity:EntityNameTrack
                                            predicate:[NSPredicate predicateWithFormat:@"fileURL == %@", [url path]]];
}

+ (BFTask<BFVoid> *)importTracksFromAudioURLs:(NSArray<NSURL *> *)audioURLs playlist:(Playlist *)playlist {
  return [TrackImportService importAudioFilesAtURLs:audioURLs withPlaylist:playlist];
};

+ (BFTask<Track *> *)findOrInsertByURL:(NSURL *)url bookmarkData:(NSData *)bookmarkData {
  return [[self trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
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
    return [TrackImportService importAudioFileAtURL:url bookmarkData:bookmarkData];
  }];
}

+ (BFTask<Track *> *)findOrInsertByURL:(nonnull NSURL *)url playlist:(Playlist *)playlist {
  return [[self trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      return task;
    }
    return [TrackImportService importAudioFileAtURL:url playlist:playlist];
  }];
}

+ (BFTask<Track *> *)findOrInsertByURL:(nonnull NSURL *)url {
  return [[self trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      return task;
    }
    return [TrackImportService importAudioFileAtURL:url playlist:nil];
  }];
}

+ (BFTask<BFVoid> *)incrementPlayCountForTrack:(Track *)track {
  NSManagedObjectID *objectID = track.objectID;
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Track *object = [context objectWithID:objectID];
    if (!object) return nil;

    object.playCount += 1;
    object.lastPlayed = [NSDate new];
    return nil;
  }];
}

@end
