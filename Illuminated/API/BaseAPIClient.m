//
//  BaseAPIClient.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import <Foundation/Foundation.h>
#import "BaseAPIClient.h"
#import "BFTask.h"
#import "BFTaskCompletionSource.h"

@implementation BaseAPIClient

+ (NSString *)baseURL {
  NSAssert(NO, @"Subclasses must override baseURL");
  return nil;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _timeoutInterval = 30.0;
    _defaultHeaders = @{
      @"Content-Type": @"application/json",
      @"Accept": @"application/json"
    };
  }
  return self;
}

- (NSURLSession *)session {
  if (!_session) {
    NSURLSessionConfiguration *config = self.sessionConfiguration ?: [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:config];
  }
  return _session;
}

- (BFTask *)GET:(NSString *)path parameters:(NSDictionary *)parameters {
  return [self requestWithMethod:BaseAPIClientMethodGET path:path parameters:parameters];
}

- (BFTask *)POST:(NSString *)path parameters:(NSDictionary *)parameters {
  return [self requestWithMethod:BaseAPIClientMethodPOST path:path parameters:parameters];
}

#pragma mark - Private Helpers

- (BFTask<id> *)requestWithMethod:(BaseAPIClientMethod)method
                             path:(NSString *)path
                       parameters:(NSDictionary *)parameters {
  NSMutableURLRequest *request = [self buildRequestWithMethod:method path:path parameters:parameters];
  
  BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
  
  NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (error) {
      [source trySetError:error];
      return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
      BFTask *parsedTask = [self handleResponse:httpResponse data:data];
      [parsedTask continueWithBlock:^id(BFTask *t) {
        if (t.error) {
          [source trySetError:t.error];
        } else {
          [source trySetResult:t.result];
        }
        return nil;
      }];
    } else {
      NSError *error = [self errorForResponse:httpResponse data:data];
      [source trySetError:error];
    }
  }];
  
  [task resume];
  
  return source.task;
}

- (NSMutableURLRequest *)buildRequestWithMethod:(BaseAPIClientMethod)method
                                           path:(NSString *)path
                                     parameters:(NSDictionary *)parameters {
  
  NSString *urlString = [NSString stringWithFormat:@"%@%@", [[self class] baseURL], path];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
  
  NSMutableURLRequest *request = [NSMutableURLRequest new];
  request.timeoutInterval = self.timeoutInterval;
  
  for (NSString *key in self.defaultHeaders) {
    [request setValue:self.defaultHeaders[key] forHTTPHeaderField:key];
  }
  
  switch (method) {
    case BaseAPIClientMethodGET:
      request.HTTPMethod = @"GET";
      if (parameters) {
        components.queryItems = [self queryItemsFromDictionary:parameters];
      }
      break;
      
    case BaseAPIClientMethodPOST:
      request.HTTPMethod = @"POST";
      if (parameters) {
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
      }
      break;
  }
  
  request.URL = components.URL;
  return request;
}

- (NSArray<NSURLQueryItem *> *)queryItemsFromDictionary:(NSDictionary *)dictionary {
  NSMutableArray *items = [NSMutableArray array];
  [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    [items addObject:[NSURLQueryItem queryItemWithName:key value:[value description]]];
  }];
  return items;
}

- (BFTask<id> *)handleResponse:(NSHTTPURLResponse *)response data:(NSData *)data {
  if (!data) {
    return [BFTask taskWithResult:nil];
  }
  
  NSError *error;
  id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  
  if (error) {
    return [BFTask taskWithError:error];
  }
  
  return [BFTask taskWithResult:json];
}

- (NSError *)errorForResponse:(NSHTTPURLResponse *)response data:(NSData *)data {
  NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  return [NSError errorWithDomain:@"BaseAPIClient"
                             code:response.statusCode
                         userInfo:@{
    NSLocalizedDescriptionKey: message ?: @"Unknown error",
    @"statusCode": @(response.statusCode)
  }];
}

@end
