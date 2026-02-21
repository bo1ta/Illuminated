//
//  FileBrowserService.h
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FileBrowserItem;
@class FileBrowserLocation;

@class BFTask<__covariant ResultType>;

@interface FileBrowserService : NSObject

- (BFTask<NSArray<FileBrowserItem *> *> *)contentsOfDirectory:(NSURL *)directoryURL bookmarkData:(NSData *)bookmarkData;

- (BFTask<NSArray<FileBrowserItem *> *> *)allFileBrowserItems;

- (BFTask<FileBrowserItem *> *)createFileBrowserItemFromLocation:(FileBrowserLocation *)fileBrowserLocation;

- (BFTask<FileBrowserItem *> *)createFileBrowserItemWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
