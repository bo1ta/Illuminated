//
//  PlaylistDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "BFTask.h"
#import <Foundation/Foundation.h>

@class Playlist, Track;

@class NSManagedObjectID;

@class NSFetchedResultsController;

NS_ASSUME_NONNULL_BEGIN

@interface PlaylistDataStore : NSObject

+ (BFTask<Playlist *> *)addToPlaylist:(Playlist *)playlist trackWithUUID:(NSUUID *)trackUUID;

+ (BFTask<Playlist *> *)createPlaylistWithName:(NSString *)name;

+ (BFTask<BFVoid> *)renamePlaylist:(Playlist *)playlist toName:(NSString *)name;

+ (NSFetchedResultsController *)fetchedResultsController;

+ (BFTask<BFVoid> *)removeFromPlaylist:(Playlist *)playlist track:(Track *)trackObjectID;

@end

NS_ASSUME_NONNULL_END
