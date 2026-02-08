//
//  CoreDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "CoreDataStore.h"
#import <Foundation/Foundation.h>

@implementation CoreDataStore

#pragma mark - Core Data stack

+ (instancetype)shared {
  static CoreDataStore *sharedCoreDataStore = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ sharedCoreDataStore = [[self alloc] init]; });
  return sharedCoreDataStore;
}

+ (id<ReadOnlyStore>)reader {
  return [self shared];
}

+ (id<WriteOnlyStore>)writer {
  return [self shared];
}

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
  @synchronized(self) {
    if (_persistentContainer == nil) {
      _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"Illuminated"];
      [_persistentContainer
          loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *_, NSError *error) {
            if (error != nil) {
              NSLog(@"Unresolved error %@, %@", error, error.userInfo);
              abort();
            }

            [self setupNotifications];
          }];
    }
  }

  return _persistentContainer;
}

- (void)setupNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleNotification)
                                               name:NSManagedObjectContextObjectsDidChangeNotification
                                             object:[self writerDerivedStorage]];
}

- (void)handleNotificationCoalesced {
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleNotificationCoalesced) object:nil];

  [self performSelector:@selector(handleNotification) withObject:nil afterDelay:0.3];
}

- (void)handleNotification {
  [[self writerDerivedStorage] performBlock:^{
    [[self writerDerivedStorage] saveIfNeeded];

    [[self viewContext] performBlock:^{ [[self viewContext] saveIfNeeded]; }];
  }];
}

- (NSManagedObjectContext *)viewContext {
  return [[self persistentContainer] viewContext];
}

@synthesize writerDerivedStorage = _writerDerivedStorage;

- (NSManagedObjectContext *)writerDerivedStorage {
  @synchronized(self) {
    if (_writerDerivedStorage == nil) {
      _writerDerivedStorage = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
      _writerDerivedStorage.parentContext = [[self persistentContainer] viewContext];
      _writerDerivedStorage.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    }

    return _writerDerivedStorage;
  }
}

#pragma mark - ReadOnlyStore

- (BFTask *)performRead:(ReadBlock)readBlock {
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];

  [[self viewContext] performBlock:^{
    id result = readBlock([self viewContext]);
    [source setResult:result];
  }];

  return source.task;
}

- (BFTask *)performReadWithError:(ReadBlockWithError)readBlock {
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];

  [[self viewContext] performBlock:^{
    NSError *error = nil;
    id result = readBlock([self viewContext], &error);

    if (error) {
      [source setError:error];
    } else {
      [source setResult:result];
    }
  }];

  return source.task;
}

- (BFTask *)fetchObjectWithID:(NSManagedObjectID *)objectID {
  return [self performReadWithError:^id(NSManagedObjectContext *context, NSError **error) {
    return [context existingObjectWithID:objectID error:error];
  }];
}

- (BFTask<NSNumber *> *)countForEntity:(NSString *)entityName {
  return [self performRead:^id(NSManagedObjectContext *context) {
    return [context countForEntityName:entityName predicate:nil];
  }];
}

- (BFTask<NSArray *> *)allObjectsForEntity:(NSString *)entityName
                                  matching:(nullable NSPredicate *)predicate
                           sortDescriptors:(nullable NSArray<NSSortDescriptor *> *)sortDescriptors {
  return [self performRead:^id(NSManagedObjectContext *context) {
    return [context allObjectsForEntityName:entityName predicate:predicate sortDescriptors:sortDescriptors ?: @[]];
  }];
}

- (BFTask *)firstObjectForEntity:(NSString *)entityName predicate:(NSPredicate *)predicate {
  return [self performRead:^id(NSManagedObjectContext *context) {
    return [context firstObjectForEntityName:entityName predicate:predicate];
  }];
}

- (BFTask *)objectForEntityName:(NSString *)entityName uniqueID:(NSUUID *)uniqueID {
  return [self firstObjectForEntity:entityName predicate:[NSPredicate predicateWithFormat:@"uniqueID == %@", uniqueID]];
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(NSString *)entityName
                                                        predicate:(nullable NSPredicate *)predicate
                                                  sortDescriptors:
                                                      (nullable NSArray<NSSortDescriptor *> *)sortDescriptors {
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
  fetchRequest.sortDescriptors = sortDescriptors ?: @[];
  fetchRequest.predicate = predicate;

  return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                             managedObjectContext:self.viewContext
                                               sectionNameKeyPath:nil
                                                        cacheName:nil];
}

#pragma mark - WriteOnlyStore

- (BFTask *)performWrite:(WriteBlock)writeBlock {
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];

  NSManagedObjectContext *writerContext = [self writerDerivedStorage];

  [writerContext performBlock:^{
    id result = writeBlock(writerContext);

    NSError *error = nil;
    if (![writerContext obtainPermanentIDsForObjects:[[writerContext insertedObjects] allObjects] error:&error]) {
      [source setError:error];
      return;
    }

    if (writerContext.hasChanges && ![writerContext save:&error]) {
      [source setError:error];
      return;
    }

    [source setResult:result ?: [NSNull null]];
  }];

  return source.task;
}

- (BFTask *)deleteObjectWithEntityName:(NSString *)entityName uniqueID:(NSUUID *)uniqueID {
  return [self performWrite:^id(NSManagedObjectContext *context) {
    NSManagedObject *object =
        [context firstObjectForEntityName:entityName
                                predicate:[NSPredicate predicateWithFormat:@"uniqueID == %@", uniqueID]];
    if (object) {
      [context deleteObject:object];
      return object;
    }
    return nil;
  }];
}

@end
