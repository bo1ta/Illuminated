//
//  FileBrowserService.m
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import "FileBrowserService.h"
#import "BookmarkResolver.h"
#import "FileBrowserItem.h"
#import "FileBrowserLocation.h"
#import "FileBrowserLocationDataStore.h"
#import <CoreServices/CoreServices.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation FileBrowserService

- (BFTask<NSArray<FileBrowserItem *> *> *)contentsOfDirectory:(NSURL *)directoryURL
                                                 bookmarkData:(NSData *)bookmarkData {
  return [BFTask
          taskFromExecutor:[BFExecutor defaultExecutor]
          withBlock:^id {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSArray<NSURL *> *contents = [fileManager
                                  contentsOfDirectoryAtURL:directoryURL
                                  includingPropertiesForKeys:@[ NSURLIsDirectoryKey, NSURLLocalizedNameKey, NSURLTypeIdentifierKey ]
                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                  error:&error];
    
    if (contents == nil) {
      return [BFTask taskWithError:error];
    }
    
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSMutableArray<FileBrowserItem *> *items = [NSMutableArray arrayWithCapacity:contents.count];
    
    for (NSURL *url in contents) {
      NSDictionary<NSURLResourceKey, id> *values =
      [url resourceValuesForKeys:@[ NSURLIsDirectoryKey, NSURLLocalizedNameKey, NSURLTypeIdentifierKey ]
                           error:nil];
      
      BOOL isDirectory = [values[NSURLIsDirectoryKey] boolValue];
      NSString *displayName = values[NSURLLocalizedNameKey] ?: url.lastPathComponent;
      NSString *typeIdentifier = values[NSURLTypeIdentifierKey];
      
      NSImage *icon = [workspace iconForFile:url.path];
      FileBrowserItem *item = [[FileBrowserItem alloc] initWithURL:url
                                                       displayName:displayName
                                                         directory:isDirectory
                                                    typeIdentifier:typeIdentifier
                                                              icon:icon
                                                      bookmarkData:bookmarkData];
      [items addObject:item];
    }
    
    NSArray<FileBrowserItem *> *sortedItems = [items
                                               sortedArrayUsingComparator:^NSComparisonResult(FileBrowserItem *left, FileBrowserItem *right) {
      if (left.isDirectory != right.isDirectory) {
        return left.isDirectory ? NSOrderedAscending : NSOrderedDescending;
      }
      return [left.displayName localizedCaseInsensitiveCompare:right.displayName];
    }];
    
    return sortedItems;
  }];
}

- (BFTask<NSArray<FileBrowserItem *> *> *)allFileBrowserItems {
  return [[FileBrowserLocationDataStore allFileBrowserLocations]
          continueWithBlock:^id(BFTask<NSArray<FileBrowserLocation *> *> *task) {
    NSArray<FileBrowserLocation *> *locations = task.result;
    if (!locations) {
      return [BFTask taskWithError:[NSError errorWithDomain:@"FileBrowserService"
                                                       code:-100
                                                   userInfo:@{
        NSLocalizedDescriptionKey :
          @"Error unwraping file browser locations resuls"
      }]];
    }
    
    if (locations.count == 0) {
      return [BFTask taskWithResult:@[]];
    }
    
    NSMutableArray<BFTask<FileBrowserItem *> *> *tasks = [NSMutableArray array];
    for (FileBrowserLocation *location in locations) {
      [tasks addObject:[self createFileBrowserItemFromLocation:location]];
    }
    
    return [BFTask taskForCompletionOfAllTasksWithResults:tasks];
  }];
}

- (BFTask<FileBrowserItem *> *)createFileBrowserItemFromLocation:(FileBrowserLocation *)fileBrowserLocation {
  if (!fileBrowserLocation.bookmarkData) {
    return [BFTask
            taskWithError:[NSError errorWithDomain:@"FileBrowserService"
                                              code:-101
                                          userInfo:@{
              NSLocalizedDescriptionKey :
                @"Error creating file browser item from location. Bookmark data is nil!"
            }]];
  }
  
  NSError *error = nil;
  NSURL *url = [BookmarkResolver resolveAndAccessBookmarkData:fileBrowserLocation.bookmarkData error:&error];
  if (error) {
    NSString *errorDescription = [NSString
                                  stringWithFormat:@"Error creating file browser item from location. Resolved URL is nil with error: %@", error];
    return [BFTask taskWithError:[NSError errorWithDomain:@"FileBrowserService"
                                                     code:-101
                                                 userInfo:@{NSLocalizedDescriptionKey : errorDescription}]];
  }
  
  FileBrowserItem *item = [self newFileBrowserItemWithURL:url bookmarkData:fileBrowserLocation.bookmarkData];
  return [BFTask taskWithResult:item];
}

- (BFTask<FileBrowserItem *> *)createFileBrowserItemWithURL:(NSURL *)url {
  FileBrowserItem *fileBrowserItem = [self newFileBrowserItemWithURL:url bookmarkData:nil];
  
  NSError *error = nil;
  NSData *bookmarkData = [BookmarkResolver bookmarkForURL:url error:&error];
  if (error) {
    return [BFTask taskWithError:error];
  }
  
  return [[FileBrowserLocationDataStore createWithDisplayName:fileBrowserItem.displayName
                                                 bookmarkData:bookmarkData
                                                 originalPath:fileBrowserItem.displayName]
          continueWithSuccessBlock:^id(BFTask<FileBrowserLocation *> *_) { return fileBrowserItem; }];
}

- (FileBrowserItem *)newFileBrowserItemWithURL:(NSURL *)url bookmarkData:(NSData *)bookmarkData {
  NSDictionary<NSURLResourceKey, id> *values =
  [url resourceValuesForKeys:@[ NSURLIsDirectoryKey, NSURLLocalizedNameKey, NSURLTypeIdentifierKey ] error:nil];
  
  BOOL isDirectory = [values[NSURLIsDirectoryKey] boolValue];
  NSString *displayName = values[NSURLLocalizedNameKey] ?: url.lastPathComponent;
  NSString *typeIdentifier = values[NSURLTypeIdentifierKey];
  NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:url.path];
  
  return [[FileBrowserItem alloc] initWithURL:url
                                  displayName:displayName
                                    directory:isDirectory
                               typeIdentifier:typeIdentifier
                                         icon:icon
                                 bookmarkData:bookmarkData];
}

@end
