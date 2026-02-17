//
//  RBStation.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import <Foundation/Foundation.h>
#import "RBStation.h"

@implementation RBStation

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super self];
  if (self) {
    _name = [dictionary[@"name"] copy] ?: @"Unknown Station";
    _url = [dictionary[@"url"] copy] ?: @"";
    _urlResolved = [dictionary[@"url_resolved"] copy] ?: dictionary[@"url"] ?: @"";
    
    NSString *stationIdString = dictionary[@"stationuuid"];
    if (stationIdString) {
      _stationUUID = [[NSUUID alloc] initWithUUIDString:stationIdString];
    }
    if (!_stationUUID) {
      _stationUUID = [NSUUID UUID];
    }
    
    NSString *serverIdString = dictionary[@"serveruuid"];
    if ([serverIdString isKindOfClass:[NSNull class]]) {
      _serverUUID = [NSUUID UUID];
    } else {
      _serverUUID = [[NSUUID alloc] initWithUUIDString:serverIdString];
    }

    _country = [dictionary[@"country"] copy];
    _countryCode = [dictionary[@"countrycode"] copy];
    _codec = [dictionary[@"codec"] copy];
    
    _bitrate = [dictionary[@"bitrate"] intValue];
    
    if ([dictionary[@"country"] isKindOfClass:[NSNull class]]) {
      _country = nil;
    }
    if ([dictionary[@"countrycode"] isKindOfClass:[NSNull class]]) {
      _countryCode = nil;
    }
    if ([dictionary[@"codec"] isKindOfClass:[NSNull class]]) {
      _codec = nil;
    }
  }
  return self;
}

@end
