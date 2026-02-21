//
//  TrackDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "TrackDataStore.h"
#import "Album.h"
#import "AlbumDataStore.h"
#import "Artist.h"
#import "ArtistDataStore.h"
#import "BFTask.h"
#import "CoreDataStore.h"
#import "Playlist.h"
#import "Track.h"
#import <Foundation/Foundation.h>

@implementation TrackDataStore

+ (BFTask<Track *> *)trackWithURL:(NSURL *)url {
  return [[CoreDataStore reader] firstObjectForEntity:EntityNameTrack
                                            predicate:[NSPredicate predicateWithFormat:@"fileURL == %@", [url path]]];
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

+ (Track *)insertTrackWithTitle:(NSString *)title
                        fileURL:(NSString *)fileURL
                    urlBookmark:(nullable NSData *)urlBookmark
                    trackNumber:(int16_t)trackNumber
                       fileType:(nullable NSString *)fileType
                        bitrate:(int16_t)bitrate
                     sampleRate:(int16_t)sampleRate
                       duration:(double)duration
                            bpm:(float)bpm
                         artist:(nullable Artist *)artist
                          album:(nullable Album *)album
                      inContext:(NSManagedObjectContext *)context {
  Track *track = [context insertNewObjectForEntityName:EntityNameTrack];
  track.uniqueID = [NSUUID new];
  track.title = title;
  track.trackNumber = trackNumber;
  track.fileType = fileType;
  track.bitrate = bitrate;
  track.sampleRate = sampleRate;
  track.duration = duration;
  track.bpm = bpm;
  track.fileURL = fileURL;
  track.urlBookmark = urlBookmark;
  track.artist = artist;
  track.album = album;

  return track;
}

+ (BFTask *)deleteTrackWithObjectID:(NSManagedObjectID *)trackObjectID {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Track *track = [context objectWithID:trackObjectID];
    if (!track) {
      return [self objectNotFoundErrorTask];
    }

    [context deleteObject:track];

    return nil;
  }];
}

+ (BFTask *)objectNotFoundErrorTask {
  return
      [BFTask taskWithError:[NSError errorWithDomain:@"TrackDataStore"
                                                code:-100
                                            userInfo:@{NSLocalizedDescriptionKey : @"Track with objectID not found"}]];
}

+ (BFTask *)updateTrackWithObjectID:(NSManagedObjectID *)trackObjectID
                          withTitle:(NSString *)title
                         artistName:(NSString *)artistName
                         albumTitle:(NSString *)albumTitle
                   albumArtworkPath:(nullable NSString *)albumArtworkPath
                              genre:(NSString *)genre
                               year:(uint16_t)year {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Track *track = [context objectWithID:trackObjectID];
    if (!track) {
      return [self objectNotFoundErrorTask];
    }

    Artist *artist = nil;
    if (artistName) {
      artist = [ArtistDataStore findOrCreateArtistWithName:artistName usingContext:context];
    }

    Album *album = nil;
    if (albumTitle) {
      album = [AlbumDataStore findOrCreateAlbumWithName:albumTitle artist:artist inContext:context];
      album.artworkPath = albumArtworkPath ?: album.artworkPath;
    }

    track.title = title;
    track.artist = artist;
    track.album = album;
    track.genre = genre;
    track.year = year;

    return nil;
  }];
}

+ (NSFetchedResultsController *)fetchedResultsController {
  return [[CoreDataStore reader] fetchedResultsControllerForEntity:EntityNameTrack predicate:nil sortDescriptors:nil];
}

@end
