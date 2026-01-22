//
//  PredicateBuilder.h
//  Illuminated
//
//  Created by Alexandru Solomon on 21.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PredicateBuilder : NSObject

+ (NSPredicate *)predicateWithName:(NSString *)name;
+ (NSPredicate *)predicateWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
