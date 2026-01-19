//
//  CoreDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <CoreData/CoreData.h>
#import "ReadOnlyStore.h"
#import "WriteOnlyStore.h"
#import "BFTaskCompletionSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataStore : NSObject <ReadOnlyStore, WriteOnlyStore>

@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (readonly) NSManagedObjectContext *viewContext;
@property (readonly) NSManagedObjectContext *writerDerivedStorage;

+ (instancetype)shared;
+ (id<ReadOnlyStore>)readOnlyStore;
+ (id<WriteOnlyStore>)writeOnlyStore;

@end

NS_ASSUME_NONNULL_END
