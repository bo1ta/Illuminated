//
//  FileBrowserService.h
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import "BFExecutor.h"
#import "BFTask.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FileBrowserItem;

@interface FileBrowserService : NSObject

- (BFTask<NSArray<FileBrowserItem *> *> *)contentsOfDirectory:(NSURL *)directoryURL;

@end

NS_ASSUME_NONNULL_END
