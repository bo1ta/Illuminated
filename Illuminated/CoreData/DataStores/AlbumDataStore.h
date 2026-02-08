//
//  AlbumDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Foundation/Foundation.h>

@class Album, Artist, NSManagedObjectContext;

NS_ASSUME_NONNULL_BEGIN

@interface AlbumDataStore : NSObject

+ (Album *)findOrCreateAlbumWithName:(NSString *)albumName
                               artist:(nullable Artist *)artist
                             inContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
