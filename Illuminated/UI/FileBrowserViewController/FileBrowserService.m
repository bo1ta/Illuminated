//
//  FileBrowserService.m
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import "FileBrowserService.h"
#import "FileBrowserItem.h"
#import <CoreServices/CoreServices.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation FileBrowserService

- (BFTask<NSArray<FileBrowserItem *> *> *)contentsOfDirectory:(NSURL *)directoryURL {
  return [BFTask taskFromExecutor:[BFExecutor defaultExecutor]
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
//                             if (icon  == nil) {
//                               NSString *fileType = typeIdentifier ?: url.pathExtension;
//                               if (fileType.length == 0) {
//                                 fileType = UTTypeData.identifier;
//                               }
//                               icon = [workspace iconForFileType:fileType];
//                             }

                             FileBrowserItem *item = [[FileBrowserItem alloc] initWithURL:url
                                                                                displayName:displayName
                                                                                  directory:isDirectory
                                                                             typeIdentifier:typeIdentifier
                                                                                       icon:icon];
                             [items addObject:item];
                           }

                           NSArray<FileBrowserItem *> *sortedItems =
                               [items sortedArrayUsingComparator:^NSComparisonResult(FileBrowserItem *left, FileBrowserItem *right) {
                                 if (left.isDirectory != right.isDirectory) {
                                   return left.isDirectory ? NSOrderedAscending : NSOrderedDescending;
                                 }
                                 return [left.displayName localizedCaseInsensitiveCompare:right.displayName];
                               }];

                           return sortedItems;
                         }];
}

@end
