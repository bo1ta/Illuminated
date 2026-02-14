//
//  RadioBrowserClient.h
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "BaseAPIClient.h"
#import "BFTask.h"

NS_ASSUME_NONNULL_BEGIN

@class RadioStation;

@interface RadioBrowserClient : BaseAPIClient

+ (NSString *)baseURL;

- (BFTask<NSArray<RadioStation *> *> *)searchStations:(NSString *)term;
- (BFTask<NSArray<RadioStation *> *> *)listAllStations;

@end

NS_ASSUME_NONNULL_END
