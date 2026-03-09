//
//  RadioStationTag+CoreDataClass.m
//  Illuminated
//
//  Created by Alexandru Solomon on 09.03.2026.
//
//

#import "RadioStationTag.h"

@implementation RadioStationTag

+ (NSFetchRequest<RadioStationTag *> *)fetchRequest {
  return [NSFetchRequest fetchRequestWithEntityName:@"RadioStationTag"];
}

@dynamic name;
@dynamic radioStations;


@end
