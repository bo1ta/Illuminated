//
//  BookmarkResolver.m
//  Illuminated
//
//  Created by Alexandru Solomon on 23.01.2026.
//

#import "BookmarkResolver.h"
#import <Foundation/Foundation.h>

NSString *const BookmarkResolverErrorDomain = @"com.illuminated.BookmarkResolverErrorDomain";

NSString *const MusicFolderBookmarkKey = @"MusicFolderBookmark";

@implementation BookmarkResolver

+ (NSURL *)resolveMusicFolder {
  NSData *bookmarkData = [[NSUserDefaults standardUserDefaults] objectForKey:MusicFolderBookmarkKey];
  if (!bookmarkData) {
    return nil;
  }
  return [self resolveAndAccessBookmarkData:bookmarkData error:nil];
}

+ (NSData *)bookmarkForMusicFolder {
  return [[NSUserDefaults standardUserDefaults] objectForKey:MusicFolderBookmarkKey];
}

+ (NSData *)storeMusicFolderBookmarkForURL:(NSURL *)url error:(NSError **)error {
  NSError *bookmarkError = nil;
  NSData *bookmarkData = [self bookmarkForURL:url error:&bookmarkError];
  if (bookmarkData) {
    [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:MusicFolderBookmarkKey];
    return bookmarkData;
  } else {
    *error = bookmarkError;
    return nil;
  }
}

+ (NSData *)bookmarkForURL:(NSURL *)url error:(NSError **)error {
  BOOL accessedSecurityScope = [url startAccessingSecurityScopedResource];
  NSError *bookmarkError = nil;
  NSURLBookmarkCreationOptions options = NSURLBookmarkCreationWithSecurityScope;
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 101300
  options |= NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess;
#endif

  NSData *bookmark = [url bookmarkDataWithOptions:options
                   includingResourceValuesForKeys:nil
                                    relativeToURL:nil
                                            error:&bookmarkError];
  if (accessedSecurityScope) {
    [url stopAccessingSecurityScopedResource];
  }

  if (bookmarkError) {
    NSLog(@"Raw error: %@", bookmarkError);
    NSLog(@"Code: %ld domain: %@", bookmarkError.code, bookmarkError.domain);
    NSLog(@"User info: %@", bookmarkError.userInfo);

    NSString *errorMessage =
        [NSString stringWithFormat:@"Error bookmarking track: %@", bookmarkError.localizedDescription];
    if (error) {
      *error = [NSError errorWithDomain:BookmarkResolverErrorDomain
                                   code:BookmarkResolverErrorDomainBookmarkDataCreationFailed
                               userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    }
    return nil;
  }

  return bookmark;
}

+ (NSURL *)URLForBookmarkData:(NSData *)data error:(NSError **)error {
  NSError *resolveError = nil;
  BOOL isStale = NO;
  NSURL *resolvedURL = [NSURL URLByResolvingBookmarkData:data
                                                 options:NSURLBookmarkResolutionWithSecurityScope
                                           relativeToURL:nil
                                     bookmarkDataIsStale:&isStale
                                                   error:&resolveError];
  if (isStale) {
    *error = [NSError errorWithDomain:BookmarkResolverErrorDomain
                                 code:BookmarkResolverErrorDomainStaleData
                             userInfo:@{NSLocalizedDescriptionKey : @"Track has stale data"}];
    return nil;
  }
  if (resolveError || !resolvedURL) {
    *error = [NSError errorWithDomain:BookmarkResolverErrorDomain
                                 code:BookmarkResolverErrorDomainResolvingFailed
                             userInfo:@{NSLocalizedDescriptionKey : @"Track failed to resolve URL"}];
    return nil;
  }

  return resolvedURL;
}

+ (NSURL *)resolveAndAccessBookmarkData:(NSData *)data error:(NSError **)error {
  NSError *resolveError = nil;
  BOOL isStale = NO;
  NSURL *resolvedURL = [NSURL URLByResolvingBookmarkData:data
                                                 options:NSURLBookmarkResolutionWithSecurityScope
                                           relativeToURL:nil
                                     bookmarkDataIsStale:&isStale
                                                   error:&resolveError];
  if (isStale) {
    *error = [NSError errorWithDomain:BookmarkResolverErrorDomain
                                 code:BookmarkResolverErrorDomainStaleData
                             userInfo:@{NSLocalizedDescriptionKey : @"Track has stale data"}];
    return nil;
  }
  if (resolveError || !resolvedURL) {
    *error = [NSError errorWithDomain:BookmarkResolverErrorDomain
                                 code:BookmarkResolverErrorDomainResolvingFailed
                             userInfo:@{NSLocalizedDescriptionKey : @"Track failed to resolve URL"}];
    return nil;
  }

  [resolvedURL startAccessingSecurityScopedResource];
  return resolvedURL;
}

+ (void)releaseAccessedURL:(NSURL *)url {
  [url stopAccessingSecurityScopedResource];
}

@end
