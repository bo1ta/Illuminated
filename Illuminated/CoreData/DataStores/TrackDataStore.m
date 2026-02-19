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
      return [BFTask
          taskWithError:[NSError errorWithDomain:@"TrackDataStore"
                                            code:-100
                                        userInfo:@{NSLocalizedDescriptionKey : @"Track with objectID not found"}]];
    }

    [context deleteObject:track];

    return nil;
  }];
}

+ (NSFetchedResultsController *)fetchedResultsController {
  return [[CoreDataStore reader] fetchedResultsControllerForEntity:EntityNameTrack predicate:nil sortDescriptors:nil];
}

@end
