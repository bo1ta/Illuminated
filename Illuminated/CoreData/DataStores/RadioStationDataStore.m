//
//  RadioStationDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import "RadioStationDataStore.h"
#import "CoreDataStore.h"
#import "RadioStation.h"

@implementation RadioStationDataStore

+ (BFTask *)radioStationsFromAPIDictionary:(APIDictionary)apiDictionary {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    NSMutableArray<RadioStation *> *results = [NSMutableArray array];
    
    for (NSDictionary *dict in apiDictionary) {
      if (!dict[@"url"]) {
        continue;
      }
      
      NSPredicate *predicate = [self predicateForDictionary:dict];
      RadioStation *radioStation = [context findOrInsertObjectForEntityName:EntityNameRadioStation
                                                                  predicate:predicate];
      radioStation.url = dict[@"url"];
      radioStation.name = dict[@"name"];
      radioStation.urlResolved = dict[@"url_resolved"];
      radioStation.country = dict[@"country"];
      radioStation.countryCode = dict[@"countrycode"];
      radioStation.codec = dict[@"codec"];
      
      if ([dict[@"bitrate"] isKindOfClass:[NSNumber class]]) {
        radioStation.bitrate = dict[@"bitrate"];
      }
      
      NSString *stationIDString = dict[@"stationuuid"];
      NSUUID *stationID = [[NSUUID alloc] initWithUUIDString:stationIDString];
      if (stationID) {
        radioStation.stationID = stationID;
      }
      
      NSString *serverIDString = [dict[@"serveruuid"] copy];
      if ([serverIDString isKindOfClass:[NSNull class]]) {
        radioStation.serverID = [NSUUID UUID];
      } else {
        radioStation.serverID = [[NSUUID alloc] initWithUUIDString:serverIDString];
      }
      
      [results addObject:radioStation];
    }
    
    return results;
  }];
}

+ (NSPredicate *)predicateForDictionary:(NSDictionary *)dictionary {
  NSString *stationIDString = dictionary[@"stationuuid"];
  NSUUID *stationID = [[NSUUID alloc] initWithUUIDString:stationIDString];
  if (stationID) {
    return [NSPredicate predicateWithFormat:@"stationID == %@", stationID];
  }

  NSString *stationURLString = dictionary[@"url"];
  if (stationURLString) {
    return [NSPredicate predicateWithFormat:@"url == %@", stationURLString];
  }
  
  return nil;
}

@end
