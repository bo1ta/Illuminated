//
//  RadioStation+CoreDataClass.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadioStation : NSManagedObject

+ (NSFetchRequest<RadioStation *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *url;
@property (nullable, nonatomic, copy) NSString *urlResolved;
@property (nullable, nonatomic, copy) NSUUID *stationID;
@property (nullable, nonatomic, copy) NSUUID *serverID;
@property (nullable, nonatomic, copy) NSString *country;
@property (nullable, nonatomic, copy) NSString *countryCode;
@property (nullable, nonatomic, copy) NSString *codec;
@property (nullable, nonatomic, copy) NSNumber *bitrate;

@end

NS_ASSUME_NONNULL_END
