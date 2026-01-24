//
//  BookmarkResolver.h
//  Illuminated
//
//  Created by Alexandru Solomon on 23.01.2026.
//

#import "Cocoa/Cocoa.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BookmarkResolverErrorDomain;

typedef NS_ENUM(NSInteger, PlaybackManagerErrorCode) {
  BookmarkResolverErrorDomainStaleData = 1000,
  BookmarkResolverErrorDomainResolvingFailed = 1001,
  BookmarkResolverErrorDomainBookmarkDataCreationFailed = 1001
};

#pragma mark - BookmarkResolver

@interface BookmarkResolver : NSObject
+ (NSData *)bookmarkForURL:(NSURL *)url error:(NSError **)error;
+ (NSURL *)resolveAndAccessBookmarkData:(NSData *)data error:(NSError **)error;
+ (void)releaseAccessedURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
