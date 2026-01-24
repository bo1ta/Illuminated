//
//  NSDictionary+Merge.m
//  Illuminated
//
//  Created by Alexandru Solomon on 24.01.2026.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+Merge.h"

@implementation NSDictionary (Merge)

- (NSDictionary *)dictionaryByMergingWithDictionary:(NSDictionary *)other {
  NSMutableDictionary *result = [self mutableCopy];
  [result addEntriesFromDictionary:other];
  return [result copy];
}

- (NSDictionary *)dictionaryByPreferringExistingOverDictionary:(NSDictionary *)other {
    if (!other || other.count == 0) return self;
    
    NSMutableDictionary *result = [self mutableCopy];
    for (NSString *key in other) {
        if (!result[key]) {
            result[key] = other[key];
        }
    }
    return [result copy];
}

@end
