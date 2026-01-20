//
//  ReadOnlyStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <Foundation/Foundation.h>
#import "Album.h"
#import "Artist.h"
#import "BFTask.h"
#import "Playlist.h"
#import "Track.h"

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^ReadBlock)(NSManagedObjectContext *context);
typedef id _Nullable (^ReadBlockWithError)(NSManagedObjectContext *context, NSError **error);

@protocol ReadOnlyStore <NSObject>

- (BFTask *)performRead:(ReadBlock)readBlock;
- (BFTask *)performReadWithError:(ReadBlockWithError)readBlock;

- (BFTask *)fetchObjectWithID:(NSManagedObjectID *)objectID;
- (BFTask<NSNumber *> *)countForEntity:(NSString *)entityName;

- (BFTask<NSArray *> *)allObjectsForEntity:(NSString *)entityName
                                  matching:(nullable NSPredicate *)predicate
                           sortDescriptors:(nullable NSArray<NSSortDescriptor *> *)sortDescriptors;

- (BFTask *)firstObjectForEntity:(NSString *)entityName predicate:(NSPredicate *)predicate;

#pragma mark - Albums

- (BFTask<Album *> *)albumWithID:(NSManagedObjectID *)objectID;
- (BFTask<NSArray<Album *> *> *)allAlbums;
- (BFTask<NSArray<Album *> *> *)albumsWithTitle:(NSString *)title
                                         artist:(nullable NSString *)artistName;
- (BFTask<NSNumber *> *)albumsCount;

#pragma mark - Tracks

- (BFTask<Track *> *)trackWithID:(NSManagedObjectID *)objectID;
- (BFTask<NSArray<Track *> *> *)allTracks;
- (BFTask<NSArray<Track *> *> *)searchTracks:(NSString *)query;
- (BFTask<NSNumber *> *)tracksCount;

#pragma mark - Artists
- (BFTask<Artist *> *)artistWithID:(NSManagedObjectID *)objectID;
- (BFTask<NSArray<Artist *> *> *)allArtists;
- (BFTask<Artist *> *)artistWithName:(NSString *)name;
- (BFTask<NSNumber *> *)artistsCount;

#pragma mark - Playlists
- (BFTask<Playlist *> *)playlistWithID:(NSManagedObjectID *)objectID;
- (BFTask<NSArray<Playlist *> *> *)allPlaylists;
- (BFTask<Playlist *> *)playlistWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
