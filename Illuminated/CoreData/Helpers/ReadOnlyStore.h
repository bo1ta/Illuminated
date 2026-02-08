//
//  ReadOnlyStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "BFTask.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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
@end

NS_ASSUME_NONNULL_END
