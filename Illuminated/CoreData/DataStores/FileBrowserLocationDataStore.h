//
//  FileBrowserLocationDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 17.02.2026.
//

#import <Foundation/Foundation.h>

@class FileBrowserLocation;
@class BFTask<__covariant ResultType>;

@interface FileBrowserLocationDataStore : NSObject

+ (BFTask<NSArray<FileBrowserLocation *> *> *)allFileBrowserLocations;

+ (BFTask<FileBrowserLocation *> *)createWithDisplayName:(NSString *)displayName
                                            bookmarkData:(NSData *)bookmarkData
                                            originalPath:(NSString *)originalPath;

@end
