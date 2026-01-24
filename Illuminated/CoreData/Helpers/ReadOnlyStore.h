//
//  ReadOnlyStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "BFTask.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Track, Album, Playlist, Artist;

typedef id _Nullable (^ReadBlock)(NSManagedObjectContext *context);
typedef id _Nullable (^ReadBlockWithError)(NSManagedObjectContext *context, NSError **error);

@protocol ReadOnlyStore<NSObject>

- (BFTask *)performRead:(ReadBlock)readBlock;
- (BFTask *)performReadWithError:(ReadBlockWithError)readBlock;

- (BFTask *)fetchObjectWithID:(NSManagedObjectID *)objectID;
- (BFTask<NSNumber *> *)countForEntity:(NSString *)entityName;

- (BFTask<NSArray *> *)allObjectsForEntity:(NSString *)entityName
                                  matching:(nullable NSPredicate *)predicate
                           sortDescriptors:(nullable NSArray<NSSortDescriptor *> *)sortDescriptors;

- (BFTask *)firstObjectForEntity:(NSString *)entityName predicate:(NSPredicate *)predicate;
- (BFTask *)objectForEntityName:(NSString *)entityName uniqueID:(NSUUID *)uniqueID;

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(NSString *)entityName
                                                        predicate:(nullable NSPredicate *)predicate
                                                  sortDescriptors:
                                                      (nullable NSArray<NSSortDescriptor *> *)sortDescriptors;

#pragma mark - Albums

- (BFTask<Album *> *)albumWithUniqueID:(NSUUID *)uniqueID;
- (BFTask<NSArray<Album *> *> *)allAlbums;
- (BFTask<NSArray<Album *> *> *)albumsWithTitle:(NSString *)title artist:(nullable NSString *)artistName;
- (BFTask<NSNumber *> *)albumsCount;

#pragma mark - Tracks

- (BFTask<Track *> *)trackWithUniqueID:(NSUUID *)uniqueID;
- (BFTask<NSArray<Track *> *> *)allTracks;
- (BFTask<NSArray<Track *> *> *)searchTracks:(NSString *)query;
- (BFTask<NSNumber *> *)tracksCount;

#pragma mark - Artists
- (BFTask<Artist *> *)artistWithUniqueID:(NSUUID *)uniqueID;
- (BFTask<NSArray<Artist *> *> *)allArtists;
- (BFTask<Artist *> *)artistWithName:(NSString *)name;
- (BFTask<NSNumber *> *)artistsCount;

#pragma mark - Playlists
- (BFTask<Playlist *> *)playlistWithUniqueID:(NSUUID *)uniqueID;
- (BFTask<NSArray<Playlist *> *> *)allPlaylists;
- (BFTask<Playlist *> *)playlistWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
