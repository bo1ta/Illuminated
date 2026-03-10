//
//  PredicateBuilder.m
//  Illuminated
//
//  Created by Alexandru Solomon on 21.01.2026.
//

#import "PredicateBuilder.h"
#import <Foundation/Foundation.h>

@implementation PredicateBuilder

+ (NSPredicate *)predicateWithName:(NSString *)name {
  return [NSPredicate predicateWithFormat:@"name == %@", name];
}

+ (NSPredicate *)predicateWithTitle:(NSString *)title {
  return [NSPredicate predicateWithFormat:@"title == %@", title];
}

@end
