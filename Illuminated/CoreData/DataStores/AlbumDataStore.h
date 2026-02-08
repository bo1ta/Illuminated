//
//  AlbumDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Album, Artist;
@class NSManagedObjectContext, NSFetchedResultsController;

@interface AlbumDataStore : NSObject

+ (Album *)findOrCreateAlbumWithName:(NSString *)albumName
                              artist:(nullable Artist *)artist
                           inContext:(NSManagedObjectContext *)context;

+ (NSFetchedResultsController *)fetchedResultsController;

@end

NS_ASSUME_NONNULL_END
