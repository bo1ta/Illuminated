//
//  RadioBrowserClient.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioBrowserClient.h"

@implementation RadioBrowserClient

+ (NSString *)baseURL {
  return @"https://de1.api.radio-browser.info";
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.defaultHeaders = @{@"Content-Type" : @"application/json", @"User-Agent" : @"Illuminated/1.0"};
  }
  return self;
}

- (BFTask<NSArray<APIDictionary> *> *)getRadioStations {
  return [self GET:@"/json/stations" parameters:nil];
}

- (BFTask<APIDictionary> *)increaseClickCountForStationID:(NSString *)stationID {
  NSString *urlPath = [NSString stringWithFormat:@"/json/url/%@", stationID];
  return [self GET:urlPath parameters:nil];
}

- (BFTask<NSArray<APIDictionary> *> *)searchStations:(NSString *)term {
  return [self GET:@"/json/stations/byname" parameters:@{@"name" : term}];
}

@end
