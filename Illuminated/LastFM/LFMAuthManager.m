//
//  LFMAuthManager.m
//  Illuminated
//
//  Created by Alexandru Solomon on 11.03.2026.
//

#import "LFMAuthManager.h"
#import "LastFMSession.h"
#import <Security/Security.h>

NSString *const KeychainServiceName = @"com.Illuminated.lastfm";
NSString *const KeychainSessionKey = @"session_key";

@implementation LFMAuthManager

@synthesize currentSession = _currentSession;

+ (LFMAuthManager *)sharedManager {
  static LFMAuthManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ sharedInstance = [[self alloc] init]; });
  return sharedInstance;
}

- (nullable LastFMSession *)currentSession {
  if (_currentSession) {
    return _currentSession;
  }

  NSDictionary *query = @{
    (id)kSecClass : (id)kSecClassGenericPassword,
    (id)kSecAttrService : KeychainServiceName,
    (id)kSecAttrAccount : KeychainSessionKey,
    (id)kSecReturnData : (id)kCFBooleanTrue,
    (id)kSecMatchLimit : (id)kSecMatchLimitOne
  };

  CFTypeRef sessionDataRef = NULL;
  OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, &sessionDataRef);

  if (status == errSecSuccess) {
    NSData *sessionData = (__bridge_transfer NSData *)sessionDataRef;
    NSError *error;
    LastFMSession *session = [NSKeyedUnarchiver unarchivedObjectOfClass:[LastFMSession class]
                                                               fromData:sessionData
                                                                  error:&error];
    if (!error) {
      _currentSession = session;
      return session;
    } else {
      NSLog(@"Failed to unarchive session: %@", error);
    }
  } else if (status != errSecItemNotFound) {
    NSLog(@"Keychain read error: %d", (int)status);
  }

  return nil;
}

- (void)setCurrentSession:(nullable LastFMSession *)currentSession {
  _currentSession = currentSession;

  if (currentSession) {
    NSError *error = nil;
    NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:currentSession
                                                requiringSecureCoding:YES
                                                                error:&error];
    if (!error) {
      NSDictionary *query = @{
        (id)kSecClass : (id)kSecClassGenericPassword,
        (id)kSecAttrService : KeychainServiceName,
        (id)kSecAttrAccount : KeychainSessionKey,
        (id)kSecValueData : sessionData
      };

      SecItemDelete((CFDictionaryRef)query);
      SecItemAdd((CFDictionaryRef)query, NULL);
    }
  } else {
    NSDictionary *query = @{
      (id)kSecClass : (id)kSecClassGenericPassword,
      (id)kSecAttrService : KeychainServiceName,
      (id)kSecAttrAccount : KeychainSessionKey
    };
    SecItemDelete((CFDictionaryRef)query);
  }
}

- (BOOL)isAuthenticated {
  return self.currentSession != nil;
}

- (void)logout {
  [self setCurrentSession:nil];
}

@end
