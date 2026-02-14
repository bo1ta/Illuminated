//
//  RadioBrowserClient.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioBrowserClient.h"
#import "RadioStation.h"

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

- (BFTask<NSArray<RadioStation *> *> *)listAllStations {
  return [[self GET:@"/json/stations" parameters:nil] continueWithSuccessBlock:^id(BFTask * task) {
    return [self decodeStationsFromJsonArray:task.result];
  }];
}

- (BFTask<NSArray<RadioStation *> *> *)searchStations:(NSString *)term {
  return [[self GET:@"/json/stations/byname" parameters:@{@"name": term}] continueWithSuccessBlock:^id(BFTask *task) {
    return [self decodeStationsFromJsonArray:task.result];
  }];
}

- (NSArray<RadioStation *> *)decodeStationsFromJsonArray:(NSArray<NSDictionary *> *)jsonArray {
  NSMutableArray *stations = [NSMutableArray array];
  for (NSDictionary *dict in jsonArray) {
    RadioStation *station = [[RadioStation alloc] initWithDictionary:dict];
    [stations addObject:station];
  }
  
  return stations;
}

@end
