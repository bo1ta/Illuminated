//
//  AlbumDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "AlbumDataStore.h"
#import "Album.h"
#import "ArtworkManager.h"
#import "CoreDataStore.h"
#import "Track.h"

@implementation AlbumDataStore

+ (Album *)findOrCreateAlbumWithName:(NSString *)albumName
                              artist:(nullable Artist *)artist
                           inContext:(NSManagedObjectContext *)context {
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

@end
