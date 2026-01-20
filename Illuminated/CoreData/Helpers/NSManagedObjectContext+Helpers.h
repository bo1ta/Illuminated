//
//  NSManagedObjectContext+Helpers.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObjectContext (Helpers)

- (NSArray *)allObjectsForEntityName:(NSString *)entityName
                           predicate:(nullable NSPredicate *)predicate
                     sortDescriptors:(nullable NSArray<NSSortDescriptor *> *)sortDescriptors;

- (nullable id)firstObjectForEntityName:(NSString *)entityName predicate:(nullable NSPredicate *)predicate;

- (NSNumber *)countForEntityName:(NSString *)entityName predicate:(nullable NSPredicate *)predicate;

- (id)insertNewObjectForEntityName:(NSString *)entityName;

- (void)deleteAllObjectsForEntityName:(NSString *)entityName;

- (BOOL)objectExistsForEntityName:(NSString *)entityName predicate:(nullable NSPredicate *)predicate;

- (id)findOrInsertObjectForEntityName:(NSString *)entityName predicate:(NSPredicate *)predicate;

- (void)saveIfNeeded;

@end

NS_ASSUME_NONNULL_END
