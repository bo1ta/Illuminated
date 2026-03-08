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

NS_ASSUME_NONNULL_BEGIN

@interface RadioStationDataStore : NSObject

+ (BFTask *)radioStationsFromAPIDictionary:(APIDictionary)apiDictionary;

+ (NSFetchedResultsController *)fetchedResultsController;

@end

NS_ASSUME_NONNULL_END
