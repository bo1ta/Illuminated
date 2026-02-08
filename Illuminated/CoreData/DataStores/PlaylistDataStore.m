//
//  PlaylistDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "PlaylistDataStore.h"
#import "CoreDataStore.h"
#import "Playlist.h"
#import <Foundation/Foundation.h>

@implementation PlaylistDataStore

+ (BFTask<Playlist *> *)addToPlaylist:(Playlist *)playlist trackWithUUID:(NSUUID *)trackUUID {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Playlist *safePlaylist = [context objectWithID:playlist.objectID];
    if (!safePlaylist) {
      return nil;
    }

    Track *track = [context firstObjectForEntityName:EntityNameTrack
                                           predicate:[NSPredicate predicateWithFormat:@"uniqueID == %@", trackUUID]];
    if (!track) {
      return nil;
    }

    [safePlaylist addTracksObject:track];
    return safePlaylist;
  }];
}

+ (BFTask<Playlist *> *)createPlaylistWithName:(NSString *)name {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Playlist *playlist = [context insertNewObjectForEntityName:EntityNamePlaylist];
    playlist.name = name;
    return playlist;
  }];
}

+ (BFTask<BFVoid> *)renamePlaylist:(Playlist *)playlist toName:(NSString *)name {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    Playlist *existingPlaylist = [context objectWithID:playlist.objectID];
    if (!existingPlaylist) return nil;

    existingPlaylist.name = name;
    return nil;
  }];
}

+ (NSFetchedResultsController *)fetchedResultsController {
  NSSortDescriptor *playlistSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
  return [[CoreDataStore reader] fetchedResultsControllerForEntity:EntityNamePlaylist
                                                         predicate:nil
                                                   sortDescriptors:@[ playlistSort ]];
}

@end
