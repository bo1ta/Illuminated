//
//  LastFMSession.m
//  Illuminated
//
//  Created by Alexandru Solomon on 10.03.2026.
//

#import "LastFMSession.h"

@implementation LastFMSession

- (instancetype)initWithName:(NSString *)name sessionKey:(NSString *)sessionKey isSubscriber:(NSNumber *)isSubscriber {
  self = [super init];
  if (self) {
    self.name = name;
    self.sessionKey = sessionKey;
    self.isSubscriber = isSubscriber;
  }
  return self;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  self = [super init];
  if (self) {
    _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
    _sessionKey = [coder decodeObjectOfClass:[NSString class] forKey:@"sessionKey"];
    _isSubscriber = [NSNumber numberWithBool:[coder decodeBoolForKey:@"isSubscriber"]];
  }
  return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder { 
  [coder encodeObject:self.name forKey:@"name"];
  [coder encodeObject:self.sessionKey forKey:@"sessionKey"];
  [coder encodeBool:self.isSubscriber.boolValue forKey:@"isSubscriber"];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end
