//
//  RadioService.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import <Cocoa/Cocoa.h>

@class BFTask;

@interface RadioService : NSObject

+ (BFTask *)getRadioStations;

+ (BFTask *)increaseClickCountForStationID:(NSString *)stationID;

@end
