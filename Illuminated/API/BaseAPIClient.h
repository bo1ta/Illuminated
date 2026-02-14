//
//  BaseAPIClient.h
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class BFTask;

typedef NS_ENUM(NSInteger, BaseAPIClientMethod) {
    BaseAPIClientMethodGET,
    BaseAPIClientMethodPOST,
};

@interface BaseAPIClient : NSObject

@property (class, readonly) NSString *baseURL;

@property(nonatomic) NSURLSessionConfiguration *sessionConfiguration;
@property(nonatomic) NSTimeInterval timeoutInterval;
@property(nonatomic) NSDictionary<NSString *, NSString *> *defaultHeaders;

@property(nonatomic) NSURLSession *session;

- (BFTask *)GET:(NSString *)path parameters:(nullable NSDictionary *)parameters;
- (BFTask *)POST:(NSString *)path parameters:(nullable NSDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END
