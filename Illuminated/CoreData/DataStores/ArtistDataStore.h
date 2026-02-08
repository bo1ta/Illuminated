//
//  ArtistDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Foundation/Foundation.h>

@class Artist, NSManagedObjectContext;

NS_ASSUME_NONNULL_BEGIN

@interface ArtistDataStore : NSObject

+ (Artist *)findOrCreateArtistWithName:(NSString *)artistName
                             inContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
