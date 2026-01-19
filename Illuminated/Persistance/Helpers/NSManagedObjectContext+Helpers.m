//
//  NSManagedObjectContext+Helpers.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <Foundation/Foundation.h>
#import "NSManagedObjectContext+Helpers.h"

@implementation NSManagedObjectContext (Helpers)

- (NSArray *)allObjectsForEntityName:(NSString *)entityName
                           predicate:(nullable NSPredicate *)predicate
                     sortDescriptors:(nullable NSArray<NSSortDescriptor *> *)sortDescriptors {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = predicate;
    request.sortDescriptors = sortDescriptors;
    
    NSError *error = nil;
    NSArray *results = [self executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Error fetching objects of type %@: %@", entityName, error.localizedDescription);
        return @[];
    }
    
    return results ?: @[];
}

- (nullable id)firstObjectForEntityName:(nonnull NSString *)entityName predicate:(nullable NSPredicate *)predicate {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = predicate;
    request.fetchLimit = 1;
    
    NSError *error = nil;
    NSArray *results = [self executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Error fetching object of type %@: %@", entityName, error.localizedDescription);
        return nil;
    }
    
    return results.firstObject;
}

- (NSNumber *)countForEntityName:(nonnull NSString *)entityName predicate:(nullable NSPredicate *)predicate {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = predicate;
    
    NSError *error = nil;
    NSInteger count = [self countForFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"[CoreData] Error counting: %@: %@", entityName, error.localizedDescription);
        return 0;
    }
    
    return [NSNumber numberWithInteger:count];
}

- (id)insertNewObjectForEntityName:(NSString *)entityName {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName
                                         inManagedObjectContext:self];
}

- (void)deleteAllObjectsForEntityName:(NSString *)entityName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.includesPropertyValues = NO;
    
    NSError *error = nil;
    NSArray *objects = [self executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"[CoreData] Error fetching objects to delete: %@", error.localizedDescription);
        return;
    }
    
    for (NSManagedObject *object in objects) {
        [self deleteObject:object];
    }
}

- (nonnull id)findOrInsertObjectForEntityName:(nonnull NSString *)entityName predicate:(nonnull NSPredicate *)predicate {
    id existingObject = [self firstObjectForEntityName:entityName predicate:predicate];
    if (existingObject != nil) {
        return existingObject;
    }
    
    return [self insertNewObjectForEntityName:entityName];
}

- (BOOL)objectExistsForEntityName:(nonnull NSString *)entityName predicate:(nullable NSPredicate *)predicate {
    id existingObject = [self firstObjectForEntityName:entityName predicate:predicate];
    return existingObject != nil;
}

- (void)saveIfNeeded {
    if (![self hasChanges]) {
        return;
    }
    
    NSError *error = nil;
    if (![self save:&error]) {
        NSLog(@"[CoreData] Failed to save context: %@", error.localizedDescription);
        [self rollback];
    }
}

@end
