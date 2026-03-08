//
//  RadioStation.h
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadioStation : NSObject

@property(nonatomic, copy) NSUUID *stationUUID;
@property(nonatomic, copy, nullable) NSUUID *serverUUID;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *url;
@property(nonatomic, copy) NSString *urlResolved;
@property(nonatomic, copy) NSString *country;
@property(nonatomic, copy) NSString *countryCode;
@property(nonatomic, copy) NSString *codec;
@property(nonatomic, assign) int bitrate;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
