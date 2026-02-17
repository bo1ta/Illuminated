//
//  RadioBrowserClient.h
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "BaseAPIClient.h"
#import "BFTask.h"

NS_ASSUME_NONNULL_BEGIN

@class RBStation, RBCountry;

@interface RadioBrowserClient : BaseAPIClient

+ (NSString *)baseURL;

- (BFTask<NSArray<RBStation *> *> *)searchStations:(NSString *)term;
- (BFTask<NSArray<RBStation *> *> *)listAllStations;

- (BFTask *)increaseClickCounterForStationUUID:(NSUUID *)stationUUID;

- (BFTask<NSArray<RBCountry *> *> *)listCountries;

@end

NS_ASSUME_NONNULL_END
