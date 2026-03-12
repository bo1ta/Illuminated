//
//  LFMAuthManager.h
//  Illuminated
//
//  Created by Alexandru Solomon on 11.03.2026.
//

#import <Cocoa/Cocoa.h>

@class LastFMSession;

NS_ASSUME_NONNULL_BEGIN

@interface LFMAuthManager : NSObject

@property(class, readonly, strong) LFMAuthManager *sharedManager;

@property(nonatomic, strong, nullable) LastFMSession *currentSession;
@property(nonatomic, strong, nullable) NSString *currentToken;

- (void)logout;
- (BOOL)isAuthenticated;

@end

NS_ASSUME_NONNULL_END
