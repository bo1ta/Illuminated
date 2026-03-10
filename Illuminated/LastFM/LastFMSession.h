//
//  LastFMSession.h
//  Illuminated
//
//  Created by Alexandru Solomon on 10.03.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface LastFMSession : NSObject <NSSecureCoding>

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *sessionKey;
@property(nonatomic, strong) NSNumber *isSubscriber;

- (instancetype)initWithName:(NSString *)name sessionKey:(NSString *)sessionKey isSubscriber:(NSNumber *)isSubscriber;

@end

NS_ASSUME_NONNULL_END
