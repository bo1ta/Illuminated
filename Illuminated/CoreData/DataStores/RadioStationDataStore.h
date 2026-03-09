//
//  Untitled.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import <Cocoa/Cocoa.h>
#import "APIDictionary.h"

@class BFTask;
@class NSFetchedResultsController;
@class NSManagedObjectID;

NS_ASSUME_NONNULL_BEGIN

@interface RadioStationDataStore : NSObject

+ (BFTask *)radioStationsFromAPIDictionaries:(NSArray<APIDictionary> *)dictionaries;

+ (BFTask *)updateIsFavoriteForRadioWithObjectID:(NSManagedObjectID *)objectID
                                      isFavorite:(BOOL)isFavorite;

+ (NSFetchedResultsController *)fetchedResultsController;

@end

NS_ASSUME_NONNULL_END
