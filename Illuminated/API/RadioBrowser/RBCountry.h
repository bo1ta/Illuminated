//
//  RBCountry.h
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RBCountry : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *isoCode;
@property (nonatomic, assign) int stationCount;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
