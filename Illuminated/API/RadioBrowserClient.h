//
//  RadioBrowserClient.h
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "BaseAPIClient.h"
#import "BFTask.h"
#import "APIDictionary.h"

NS_ASSUME_NONNULL_BEGIN

@class RBStation;

@interface RadioBrowserClient : BaseAPIClient

+ (NSString *)baseURL;

- (BFTask<NSArray<APIDictionary> *> *)searchStations:(NSString *)term;
- (BFTask<NSArray<APIDictionary> *> *)getRadioStations;
- (BFTask<APIDictionary> *)increaseClickCountForStationID:(NSString *)stationID;

@end

NS_ASSUME_NONNULL_END
