//
//  FileBrowserLocationDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 17.02.2026.
//

#import "FileBrowserLocationDataStore.h"
#import "BFTask.h"
#import "CoreDataStore.h"
#import "FileBrowserLocation.h"

@implementation FileBrowserLocationDataStore

+ (BFTask<NSArray<FileBrowserLocation *> *> *)allFileBrowserLocations {
  return [[CoreDataStore reader] allObjectsForEntity:EntityNameFileBrowserLocation
                                            matching:nil
                                     sortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"displayOrder"
                                                                                      ascending:YES] ]];
}

+ (BFTask<FileBrowserLocation *> *)createWithDisplayName:(NSString *)displayName
                                            bookmarkData:(NSData *)bookmarkData
                                            originalPath:(NSString *)originalPath {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    FileBrowserLocation *fileBrowserLocation = [context insertNewObjectForEntityName:EntityNameFileBrowserLocation];
    fileBrowserLocation.displayName = displayName;
    fileBrowserLocation.bookmarkData = bookmarkData;
    fileBrowserLocation.originalPath = originalPath;
    fileBrowserLocation.dateAdded = [NSDate date];

    return fileBrowserLocation;
  }];
}

@end
