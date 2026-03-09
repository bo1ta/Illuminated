//
//  RadioStationDataStore.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import "RadioStationDataStore.h"
#import "CoreDataStore.h"
#import "RadioStationTag.h"
#import "RadioStation.h"
#import "BFTask.h"

@implementation RadioStationDataStore

+ (NSFetchedResultsController *)fetchedResultsController {
  return [[CoreDataStore reader] fetchedResultsControllerForEntity:EntityNameRadioStation
                                                         predicate:nil
                                                   sortDescriptors:nil];
}

+ (BFTask *)updateIsFavoriteForRadioWithObjectID:(NSManagedObjectID *)objectID
                                      isFavorite:(BOOL)isFavorite {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    RadioStation *radioStation = [context objectWithID:objectID];
    if (radioStation) {
      radioStation.isFavorite = isFavorite;
    }
    return nil;
  }];
}

+ (BFTask *)radioStationsFromAPIDictionaries:(NSArray<APIDictionary> *)dictionaries {
  return [[self cleanUpDeadTags] continueWithBlock:^id(BFTask *_) {
    return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
      NSMutableArray<RadioStation *> *results = [NSMutableArray array];
      
      for (NSDictionary *dict in dictionaries) {
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
        radioStation.favicon = dict[@"favicon"];
        radioStation.homepage = dict[@"homepage"];
        radioStation.serverIDFallback = dict[@"stationuuid"];
        
        if ([dict[@"bitrate"] isKindOfClass:[NSNumber class]]) {
          radioStation.bitrate = dict[@"bitrate"];
        }
        
        if ([dict[@"clickcount"] isKindOfClass:[NSNumber class]]) {
          radioStation.clickCount = dict[@"clickCount"];
        }
        
        if ([dict[@"tags"] isKindOfClass:[NSString class]] && [dict[@"tags"] length] > 0) {
          NSArray<NSString *> *tags = [dict[@"tags"] componentsSeparatedByString:@","];
          for (NSString *tagName in tags) {
            if (tagName.length == 0) { continue; }
            RadioStationTag *radioTag = [self findOrCreateTagWithName:tagName inContext:context];
            radioTag.name = tagName;
            [radioStation addTagsObject:radioTag];
            // Too many tags are too many
            break;
          }
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
  }];
}

+ (RadioStationTag *)findOrCreateTagWithName:(NSString *)tagName inContext:(NSManagedObjectContext *)context {
  return [context findOrInsertObjectForEntityName:EntityNameRadioStationTag
                                                             predicate:[NSPredicate predicateWithFormat:@"name == %@", tagName]];
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

#pragma mark - Utility

+ (BFTask *)cleanUpDeadTags {
  return [[CoreDataStore writer] performWrite:^id(NSManagedObjectContext *context) {
    NSArray<RadioStationTag *> *tags = [context allObjectsForEntityName:EntityNameRadioStationTag
                                                             predicate:[NSPredicate predicateWithFormat:@"name == nil"]
                                                       sortDescriptors:nil];
    NSLog(@"Found %i tags", (unsigned int)tags.count);
    
    for (RadioStationTag *tag in tags) {
      [context deleteObject:tag];
    }
    
    return nil;
  }];
}

@end
