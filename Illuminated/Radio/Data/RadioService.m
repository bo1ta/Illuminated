//
//  RadioService.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import "RadioService.h"
#import "RadioBrowserClient.h"
#import "BFTask.h"
#import "RadioStationDataStore.h"

@implementation RadioService

+ (BFTask *)getRadioStations {
  return [[self.client getRadioStations] continueWithSuccessBlock:^id(BFTask<NSArray<APIDictionary> *> *task) {
    return [RadioStationDataStore radioStationsFromAPIDictionaries:task.result];
  }];
}

+ (BFTask *)increaseClickCountForStationID:(NSString *)stationID {
  BFTask *task = [self.client increaseClickCountForStationID:stationID];
  return [task continueWithBlock:^id(BFTask<APIDictionary> *task) {
    if (task.error) {
      NSLog(@"Error increasing click count for station: %@", task.error.localizedDescription);
    }
    return nil;
  }];
}

+ (RadioBrowserClient *)client {
  return [[RadioBrowserClient alloc] init];
}

@end
