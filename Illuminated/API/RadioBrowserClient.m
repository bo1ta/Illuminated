//
//  RadioBrowserClient.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioBrowserClient.h"
#import "RBStation.h"

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

- (BFTask<NSArray<RBStation *> *> *)listAllStations {
  return [[self GET:@"/json/stations" parameters:nil] continueWithSuccessBlock:^id(BFTask * task) {
    return [self decodeStationsFromJsonArray:task.result];
  }];
}

- (BFTask<APIDictionary> *)listAllStationsDictionary {
  return [self GET:@"/json/stations" parameters:nil];
}

- (BFTask<APIDictionary> *)increaseClickCountForStationID:(NSString *)stationID {
  NSString *urlPath = [NSString stringWithFormat:@"/json/url/%@", stationID];
  return [self GET:urlPath parameters:nil];
}

- (BFTask<NSArray<RBStation *> *> *)searchStations:(NSString *)term {
  return [[self GET:@"/json/stations/byname" parameters:@{@"name": term}] continueWithSuccessBlock:^id(BFTask *task) {
    return [self decodeStationsFromJsonArray:task.result];
  }];
}

- (APIDictionary)decodeStationsFromJsonArray:(NSArray<NSDictionary *> *)jsonArray {
  NSMutableArray *stations = [NSMutableArray array];
  for (NSDictionary *dict in jsonArray) {
    RBStation *station = [[RBStation alloc] initWithDictionary:dict];
    [stations addObject:station];
  }
  
  return stations;
}

@end
