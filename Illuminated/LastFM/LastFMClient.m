//
//  LastFMClient.m
//  Illuminated
//
//  Created by Alexandru Solomon on 10.03.2026.
//

#import "LastFMClient.h"
#import "Album.h"
#import "Artist.h"
#import "BFTask.h"
#import "LastFMSession.h"
#import "Track.h"
#import <CommonCrypto/CommonDigest.h>

@implementation LastFMClient

+ (NSString *)baseURL {
  return @"https://ws.audioscrobbler.com/2.0";
}

- (BFTask<NSString *> *)fetchAuthToken {
  NSString *apiKey = [self getAPIKey];
  NSString *secret = [self sharedSecret];
  if (!apiKey || !secret) {
    return [BFTask taskWithError:[NSError errorWithDomain:@"LastFMClient"
                                                     code:-100
                                                 userInfo:@{NSLocalizedDescriptionKey : @"LastFM API Keys not found"}]];
  }

  NSMutableDictionary *params = [@{@"method" : @"auth.gettoken", @"api_key" : apiKey, @"format" : @"json"} mutableCopy];

  NSString *apiSignature = [self generateAPISignatureWithParams:params secret:secret];
  params[@"api_sig"] = apiSignature;

  return [[self GET:@"" parameters:params] continueWithSuccessBlock:^id _Nullable(BFTask *_Nonnull task) {
    NSDictionary *dict = task.result;
    NSString *token = dict[@"token"];
    if (token) {
      return [BFTask taskWithResult:token];
    }
    return [BFTask
        taskWithError:[NSError errorWithDomain:@"LastFMClient"
                                          code:-100
                                      userInfo:@{NSLocalizedDescriptionKey : @"Failed to parse token response"}]];
  }];
}

- (nullable NSURL *)getAuthorizationURLWithToken:(NSString *)token {
  NSString *apiKey = [self getAPIKey];
  if (!apiKey) {
    return nil;
  }

  NSString *authURL = [NSString stringWithFormat:@"https://www.last.fm/api/auth/?api_key=%@&token=%@", apiKey, token];
  return [NSURL URLWithString:authURL];
}

- (BFTask<LastFMSession *> *)fetchSessionWithToken:(NSString *)token {
  NSString *apiKey = [self getAPIKey];
  NSString *secret = [self sharedSecret];
  if (!apiKey || !secret) {
    return [BFTask taskWithError:[NSError errorWithDomain:@"LastFMClient"
                                                     code:-100
                                                 userInfo:@{NSLocalizedDescriptionKey : @"LastFM API Keys not found"}]];
  }

  NSMutableDictionary *params = [@{
    @"method" : @"auth.getsession",
    @"api_key" : apiKey,
    @"token" : token,
  } mutableCopy];

  NSString *apiSignature = [self generateAPISignatureWithParams:params secret:secret];
  params[@"api_sig"] = apiSignature;
  params[@"format"] = @"json";

  return [[self GET:@"" parameters:params] continueWithSuccessBlock:^id _Nullable(BFTask *_Nonnull task) {
    NSDictionary *dict = task.result;
    NSDictionary *session = dict[@"session"];

    NSString *name = session[@"name"];
    NSString *key = session[@"key"];
    NSNumber *isSubscriber = session[@"subscriber"];
    if (!name || !key || [isSubscriber isKindOfClass:[NSNull class]]) {
      return [BFTask taskWithError:[NSError errorWithDomain:@"LastFMClient"
                                                       code:-100
                                                   userInfo:@{
                                                     NSLocalizedDescriptionKey :
                                                         @"LastFM FetchSession response could not be parsed"
                                                   }]];
    }

    return [BFTask taskWithResult:[[LastFMSession alloc] initWithName:name sessionKey:key isSubscriber:isSubscriber]];
  }];
}

- (BFTask *)updateNowPlayingForTrack:(Track *)track withSession:(LastFMSession *)session {
  if (!track.title || !track.artist.name) {
    return [BFTask
        taskWithError:
            [NSError errorWithDomain:@"LastFMClient"
                                code:-100
                            userInfo:@{
                              NSLocalizedDescriptionKey :
                                  @"LastFM updateNowPlaying cannot be called with invalid track title or artist name"
                            }]];
  }

  NSString *apiKey = [self getAPIKey];
  NSString *secret = [self sharedSecret];
  if (!apiKey || !secret) {
    return [BFTask taskWithError:[NSError errorWithDomain:@"LastFMClient"
                                                     code:-100
                                                 userInfo:@{NSLocalizedDescriptionKey : @"LastFM API Keys not found"}]];
  }

  NSString *token = session.sessionKey;
  NSMutableDictionary *body = [@{
    @"method" : @"track.updateNowPlaying",
    @"api_key" : apiKey,
    @"artist" : track.artist.name,
    @"track" : track.title,
    @"sk" : token
  } mutableCopy];

  if (track.album.title) {
    body[@"album"] = track.album.title;
  }

  NSString *apiSignature = [self generateAPISignatureWithParams:body secret:secret];
  body[@"api_sig"] = apiSignature;
  body[@"format"] = @"json";

  return [self POSTFormEncoded:@"" body:body];
}

- (BFTask *)scrobbleTrack:(Track *)track startedAt:(NSDate *)startDate withSession:(LastFMSession *)session {
  if (!track.title || !track.artist.name) {
    return [BFTask
        taskWithError:[NSError errorWithDomain:@"LastFMClient"
                                          code:-100
                                      userInfo:@{
                                        NSLocalizedDescriptionKey :
                                            @"LastFM scrobble cannot be called with invalid track title or artist name"
                                      }]];
  }

  NSString *apiKey = [self getAPIKey];
  NSString *secret = [self sharedSecret];
  if (!apiKey || !secret) {
    return [BFTask taskWithError:[NSError errorWithDomain:@"LastFMClient"
                                                     code:-100
                                                 userInfo:@{NSLocalizedDescriptionKey : @"LastFM API Keys not found"}]];
  }

  NSMutableDictionary *body = [@{
    @"method" : @"track.scrobble",
    @"api_key" : apiKey,
    @"artist" : track.artist.name,
    @"track" : track.title,
    @"timestamp" : [@((NSInteger)[startDate timeIntervalSince1970]) stringValue],
    @"sk" : session.sessionKey
  } mutableCopy];

  if (track.album.title) {
    body[@"album"] = track.album.title;
  }

  NSString *apiSignature = [self generateAPISignatureWithParams:body secret:secret];
  body[@"api_sig"] = apiSignature;
  body[@"format"] = @"json";

  return [self POSTFormEncoded:@"" body:body];
}

#pragma mark - Private Helpers

- (nullable NSString *)generateAPISignatureWithParams:(NSDictionary<NSString *, NSString *> *)params
                                               secret:(NSString *)secret {
  NSArray *sortedKeys = [params.allKeys sortedArrayUsingSelector:@selector(compare:)];
  NSMutableString *concat = [NSMutableString string];
  for (NSString *key in sortedKeys) {
    [concat appendString:key];
    [concat appendString:params[key]];
  }
  [concat appendString:secret];

  const char *cStr = [concat UTF8String];
  unsigned char digest[CC_MD5_DIGEST_LENGTH];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
#pragma clang diagnostic pop

  NSMutableString *signature = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [signature appendFormat:@"%02x", digest[i]];
  }

  return signature;
}

- (nullable NSString *)sharedSecret {
  NSString *obfuscatedBase64 = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"LASTFM_SECRET_KEY"];
  if (obfuscatedBase64.length == 0) {
    NSLog(@"LastFM secret missing from Info.plist");
    return nil;
  }
  NSData *base64Decoded = [[NSData alloc] initWithBase64EncodedString:obfuscatedBase64
                                                              options:NSDataBase64DecodingIgnoreUnknownCharacters];
  if (!base64Decoded) {
    NSLog(@"LastFM secret: Base64 decode failed - check the string");
    return nil;
  }

  NSMutableData *mutableData = [base64Decoded mutableCopy];
  uint8_t *bytes = (uint8_t *)mutableData.mutableBytes;
  NSUInteger length = mutableData.length;

  const uint8_t xorKey = 0x5A;
  for (NSUInteger i = 0; i < length; i++) {
    bytes[i] ^= xorKey;
  }

  NSString *secret = [[NSString alloc] initWithData:mutableData encoding:NSUTF8StringEncoding];
  if (!secret || secret.length == 0) {
    NSLog(@"LastFM secret: Failed to convert decoded bytes to string");
    return nil;
  }

  return secret;
}

- (nullable NSString *)getAPIKey {
  return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"LASTFM_API_KEY"];
}

@end
