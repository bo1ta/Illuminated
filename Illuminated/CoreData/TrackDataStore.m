//
//  TrackDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Foundation/Foundation.h>
#import "TrackDataStore.h"
#import "CoreDataStore.h"
#import "Track.h"
#import "Playlist.h"
#import "TrackImportService.h"

@implementation TrackDataStore

+ (BFTask *)importTracksFromAudioURLs:(NSArray<NSURL *> *)audioURLs
                             playlist:(Playlist *)playlist {
  return [TrackImportService importAudioFilesAtURLs:audioURLs withPlaylist:playlist];
};

+ (BFTask<Track *> *)findOrInsertByURL:(NSURL *)url
                          bookmarkData:(NSData *)bookmarkData {
  return [[[CoreDataStore reader] trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      return task;
    }
    return [TrackImportService importAudioFileAtURL:url
                                           bookmarkData:bookmarkData];
  }];
}

+ (BFTask<Track *> *)findOrInsertByURL:(nonnull NSURL *)url
                              playlist:(Playlist *)playlist {
  return [[[CoreDataStore reader] trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      return task;
    }
    return [TrackImportService importAudioFileAtURL:url
                                           playlist:playlist];
  }];
}

+ (BFTask<Track *> *)findOrInsertByURL:(nonnull NSURL *)url {
  return  [[[CoreDataStore reader] trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      return task;
    }
    return [TrackImportService importAudioFileAtURL:url
                                           playlist:nil];
  }];
}

@end
