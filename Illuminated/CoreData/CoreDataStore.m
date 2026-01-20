//
//  CoreDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "CoreDataStore.h"
#import "NSManagedObjectContext+Helpers.h"
#import <Foundation/Foundation.h>

@implementation CoreDataStore

#pragma mark - Core Data stack

+ (instancetype)shared {
  static CoreDataStore *sharedCoreDataStore = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedCoreDataStore = [[self alloc] init];
  });
  return sharedCoreDataStore;
}

+ (id<ReadOnlyStore>)readOnlyStore {
  return [self shared];
}

+ (id<WriteOnlyStore>)writeOnlyStore {
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

    [[self viewContext] performBlock:^{
      [[self viewContext] saveIfNeeded];
    }];
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
  return [self performRead:^id _Nullable(NSManagedObjectContext *_Nonnull context) {
    return [context allObjectsForEntityName:entityName predicate:predicate sortDescriptors:sortDescriptors ?: @[]];
  }];
}

- (BFTask *)firstObjectForEntity:(nonnull NSString *)entityName predicate:(nonnull NSPredicate *)predicate {
  return [self performRead:^id _Nullable(NSManagedObjectContext *_Nonnull context) {
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
    NSError *error = nil;
    id result = writeBlock(writerContext, &error);

    if (error) {
      [source setError:error
                           ?: [NSError errorWithDomain:@"CoreDataStore"
                                                  code:-1
                                              userInfo:@{NSLocalizedDescriptionKey : @"Write block returned nil"}]];
      return;
    }

    if (![writerContext obtainPermanentIDsForObjects:[[writerContext insertedObjects] allObjects] error:&error]) {
      [source setError:error];
      return;
    }

    if (![writerContext save:&error]) {
      [source setError:error];
      return;
    }

    [source setResult:result];
  }];

  return source.task;
}

#pragma mark - Album

- (BFTask<Album *> *)albumWithUniqueID:(NSUUID *)uniqueID {
  return [self objectForEntityName:EntityNameAlbum uniqueID:uniqueID];
}

- (BFTask<NSArray<Album *> *> *)albumsWithTitle:(nonnull NSString *)title artist:(nullable NSString *)artistName {
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title LIKE %@", title];
  NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"year" ascending:NO];
  return [self allObjectsForEntity:EntityNameAlbum matching:predicate sortDescriptors:@[ sort ]];
}

- (BFTask<NSNumber *> *)albumsCount {
  return [self countForEntity:EntityNameAlbum];
}

- (BFTask<NSArray<Album *> *> *)allAlbums {
  return [self allObjectsForEntity:EntityNameAlbum matching:nil sortDescriptors:nil];
}

- (BFTask<NSManagedObjectID *> *)createAlbumWithTitle:(nonnull NSString *)title
                                                 year:(nullable NSNumber *)year
                                          artworkPath:(nullable NSString *)artworkPath
                                             duration:(double)duration
                                                genre:(nullable NSString *)genre {
  return [self performWrite:^id _Nullable(NSManagedObjectContext *_Nonnull context,
                                          NSError *__autoreleasing _Nullable *_Nullable _) {
    Album *album = [context insertNewObjectForEntityName:EntityNameAlbum];
    [album setUniqueID:[NSUUID new]];
    [album setTitle:title];
    [album setYear:[year intValue]];
    [album setArtworkPath:artworkPath];
    [album setDuration:duration];
    [album setGenre:genre];

    return album;
  }];
}

#pragma mark - Artist

- (BFTask<NSArray<Artist *> *> *)allArtists {
  return [self allObjectsForEntity:EntityNameArtist matching:nil sortDescriptors:nil];
}

- (BFTask<Artist *> *)artistWithUniqueID:(NSUUID *)uniqueID {
  return [self objectForEntityName:EntityNameArtist uniqueID:uniqueID];
}

- (BFTask<Artist *> *)artistWithName:(nonnull NSString *)name {
  return [self firstObjectForEntity:EntityNameArtist predicate:[NSPredicate predicateWithFormat:@"name == %@", name]];
}

- (BFTask<NSNumber *> *)artistsCount {
  return [self countForEntity:EntityNameArtist];
}

- (BFTask *)createArtistWithName:(nonnull NSString *)name {
  return [self performWrite:^id _Nullable(NSManagedObjectContext *_Nonnull context,
                                          NSError *__autoreleasing _Nullable *_Nullable _) {
    Artist *artist = [context firstObjectForEntityName:EntityNameArtist
                                             predicate:[NSPredicate predicateWithFormat:@"name == %@", name]];
    if (!artist) {
      artist = [context insertNewObjectForEntityName:EntityNameArtist];
      [artist setUniqueID:[NSUUID new]];
      [artist setName:name];
    }

    return artist;
  }];
}

#pragma mark - Playlist

- (BFTask<NSArray<Playlist *> *> *)allPlaylists {
  return [self allObjectsForEntity:EntityNamePlaylist matching:nil sortDescriptors:nil];
}

- (BFTask<Playlist *> *)playlistWithUniqueID:(NSUUID *)uniqueID {
  return [self objectForEntityName:EntityNamePlaylist uniqueID:uniqueID];
}

- (BFTask<Playlist *> *)playlistWithName:(nonnull NSString *)name {
  return [self firstObjectForEntity:EntityNamePlaylist
                          predicate:[NSPredicate predicateWithFormat:@"name LIKE %@", name]];
}

#pragma mark - Track

- (BFTask<NSArray<Track *> *> *)allTracks {
  return [self allObjectsForEntity:EntityNameTrack matching:nil sortDescriptors:nil];
}

- (BFTask<Track *> *)trackWithUniqueID:(NSUUID *)uniqueID {
  return [self objectForEntityName:EntityNameTrack uniqueID:uniqueID];
}

- (BFTask<NSArray<Track *> *> *)searchTracks:(nonnull NSString *)query {
  return [self allObjectsForEntity:EntityNameTrack
                          matching:[NSPredicate predicateWithFormat:@"title LIKE %@", query]
                   sortDescriptors:nil];
}

- (BFTask<NSNumber *> *)tracksCount {
  return [self countForEntity:EntityNameTrack];
}

- (BFTask<NSManagedObjectID *> *)createTrackWithTitle:(nullable NSString *)title
                                          trackNumber:(int16_t)trackNumber
                                              fileURL:(nullable NSString *)fileURL
                                             fileType:(nullable NSString *)fileType
                                              bitrate:(int16_t)bitrate
                                           sampleRate:(int16_t)sampleRate
                                             duration:(double)duration {
  return [self performWrite:^id _Nullable(NSManagedObjectContext *_Nonnull context,
                                          NSError *__autoreleasing _Nullable *_Nullable _) {
    Track *track = [context insertNewObjectForEntityName:EntityNameTrack];
    [track setUniqueID:[NSUUID new]];
    [track setTitle:title];
    [track setTrackNumber:trackNumber];
    [track setFileURL:fileURL];
    [track setFileType:fileType];
    [track setBitrate:bitrate];
    [track setSampleRate:sampleRate];
    [track setDuration:duration];
    [track setPlayCount:0];
    [track setLastPlayed:[NSDate now]];

    return track;
  }];
}

@end
