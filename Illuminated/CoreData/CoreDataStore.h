//
//  CoreDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "BFTaskCompletionSource.h"
#import "NSManagedObjectContext+Helpers.h"
#import "ReadOnlyStore.h"
#import "WriteOnlyStore.h"
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - EntityName

typedef NSString *EntityName NS_STRING_ENUM;
extern EntityName const EntityNameAlbum;
extern EntityName const EntityNameArtist;
extern EntityName const EntityNameTrack;
extern EntityName const EntityNamePlaylist;
extern EntityName const EntityNameFileBrowserLocation;
extern EntityName const EntityNameRadioStation;

#pragma mark - CoreDataStore Interface

@interface CoreDataStore : NSObject<ReadOnlyStore, WriteOnlyStore>

@property(readonly, strong) NSPersistentContainer *persistentContainer;
@property(readonly) NSManagedObjectContext *viewContext;
@property(readonly) NSManagedObjectContext *writerDerivedStorage;

+ (instancetype)shared;
+ (id<ReadOnlyStore>)reader;
+ (id<WriteOnlyStore>)writer;

@end

NS_ASSUME_NONNULL_END
