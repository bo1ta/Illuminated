//
//  LastFMClient.h
//  Illuminated
//
//  Created by Alexandru Solomon on 10.03.2026.
//

#import <Cocoa/Cocoa.h>
#import "BaseAPIClient.h"

@class BFTask<__covariant ResultType>;
@class LastFMSession;

NS_ASSUME_NONNULL_BEGIN

@interface LastFMClient : BaseAPIClient

- (BFTask<NSString *> *)fetchAuthToken;

- (nullable NSURL *)getAuthorizationURLWithToken:(NSString *)token;

- (BFTask<LastFMSession *> *)fetchSessionWithToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
