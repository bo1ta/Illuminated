//
//  RBCountry.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import <Foundation/Foundation.h>
#import "RBCountry.h"

@implementation RBCountry

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  self = [super self];
  if (self) {
    _name = [dictionary[@"name"] copy];
    _isoCode = [dictionary[@"iso_3166_1"] copy];
    _stationCount = [dictionary[@"stationcount"] intValue];
  }
  return self;
}

@end
