//
//  ArtistDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Foundation/Foundation.h>
#import "CoreDataStore.h"
#import "ArtistDataStore.h"
#import "Artist.h"

@implementation ArtistDataStore

+ (Artist *)findOrCreateArtistWithName:(NSString *)artistName
                             inContext:(NSManagedObjectContext *)context {
  Artist *artist = [context firstObjectForEntityName:EntityNameArtist
                                           predicate:[NSPredicate predicateWithFormat:@"name == %@", artistName]];
  if (!artist) {
    artist = [context insertNewObjectForEntityName:EntityNameArtist];
    artist.uniqueID = [NSUUID new];
    artist.name = artistName;
  }

  return artist;
}

@end
