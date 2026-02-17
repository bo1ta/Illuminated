//
//  RadioBrowserClient.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioBrowserClient.h"
#import "RBStation.h"
#import "RBCountry.h"

@implementation RadioBrowserClient

+ (NSString *)baseURL {
  return @"https://de1.api.radio-browser.info";
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.defaultHeaders = @{
            @"Content-Type": @"application/json",
            @"User-Agent": @"Illuminated/1.0"
        };
    }
    return self;
}

- (BFTask<NSArray<RBCountry *> *> *)listCountries {
  return [[self GET:@"/json/countries" parameters:nil] continueWithSuccessBlock:^id(BFTask *task) {
    NSArray *jsonArray = task.result;
    NSMutableArray *countries = [NSMutableArray array];
    
    for (NSDictionary *dict in jsonArray) {
      RBCountry *country = [[RBCountry alloc] initWithDictionary:dict];
      [countries addObject:country];
    }
    
    return countries;
  }];
}

- (BFTask *)increaseClickCounterForStationUUID:(NSUUID *)stationUUID {
  NSString *path = [NSString stringWithFormat:@"/json/url/%@", [stationUUID UUIDString]];
  return [self POST:path parameters:nil];
}

- (BFTask<NSArray<RBStation *> *> *)listAllStations {
  return [[self GET:@"/json/stations" parameters:nil] continueWithSuccessBlock:^id(BFTask * task) {
    return [self decodeStationsFromJsonArray:task.result];
  }];
}

- (BFTask<NSArray<RBStation *> *> *)searchStations:(NSString *)term {
  return [[self GET:@"/json/stations/byname" parameters:@{@"name": term}] continueWithSuccessBlock:^id(BFTask *task) {
    return [self decodeStationsFromJsonArray:task.result];
  }];
}

- (NSArray<RBStation *> *)decodeStationsFromJsonArray:(NSArray<NSDictionary *> *)jsonArray {
  NSMutableArray *stations = [NSMutableArray array];
  for (NSDictionary *dict in jsonArray) {
    RBStation *station = [[RBStation alloc] initWithDictionary:dict];
    [stations addObject:station];
  }
  
  return stations;
}

@end
