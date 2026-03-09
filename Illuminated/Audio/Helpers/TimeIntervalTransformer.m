//
//  TimeIntervalTransformer.m
//  Illuminated
//
//  Created by Alexandru Solomon on 09.03.2026.
//

#import "TimeIntervalTransformer.h"

@implementation TimeIntervalTransformer

+ (Class)transformedValueClass {
  return [NSString class];
}
+ (BOOL)allowsReverseTransformation {
  return NO;
}

- (id)transformedValue:(id)value {
  if (![value respondsToSelector:@selector(doubleValue)]) return @"0:00";
  NSTimeInterval seconds = [value doubleValue];
  NSInteger mins = (NSInteger)seconds / 60;
  NSInteger secs = (NSInteger)seconds % 60;
  return [NSString stringWithFormat:@"%ld:%02ld", mins, secs];
}

@end
