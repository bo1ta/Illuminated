//
//  ScrobbleTracker.h
//  Illuminated
//
//  Created by Alexandru Solomon on 11.03.2026.
//

#import <Cocoa/Cocoa.h>

@class LastFMClient;
@class LastFMSession;

NS_ASSUME_NONNULL_BEGIN

@interface ScrobbleTracker : NSObject

- (instancetype)initWithLastFMClient:(LastFMClient *)client
                             session:(LastFMSession *)session;

- (void)start;

@end

NS_ASSUME_NONNULL_END
