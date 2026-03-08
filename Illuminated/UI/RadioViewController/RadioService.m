//
//  RadioService.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import "RadioService.h"
#import "RadioBrowserClient.h"
#import "RadioStationDataStore.h"

@implementation RadioService

+ (BFTask *)getRadioStations {
  return [[[self client] listAllStationsDictionary] continueWithSuccessBlock:^id (BFTask<APIDictionary> *task) {
    return [RadioStationDataStore radioStationsFromAPIDictionary:task.result];
  }];
}

+ (BFTask *)increaseClickCountForStationID:(NSString *)stationID {
  return [[[self client] increaseClickCountForStationID:stationID] continueWithBlock:^id(BFTask<APIDictionary> *task) {
    if (task.error) {
      NSLog(@"Error increasing click count for station");
    } else {
      NSLog(@"All good!");
    }
    return nil;
  }];
}

+ (RadioBrowserClient *)client {
  return [[RadioBrowserClient alloc] init];
}

@end
