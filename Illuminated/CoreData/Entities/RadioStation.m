//
//  RadioStation+CoreDataProperties.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//
//

#import "RadioStation.h"

@implementation RadioStation

+ (NSFetchRequest<RadioStation *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"RadioStation"];
}

@dynamic name;
@dynamic url;
@dynamic urlResolved;
@dynamic stationID;
@dynamic serverID;
@dynamic country;
@dynamic countryCode;
@dynamic codec;
@dynamic bitrate;
@dynamic clickCount;
@dynamic favicon;
@dynamic homepage;
@dynamic serverIDFallback;
@dynamic isFavorite;
@dynamic tags;

@end
