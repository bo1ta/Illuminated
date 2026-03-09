//
//  RadioStationTag+CoreDataClass.h
//  Illuminated
//
//  Created by Alexandru Solomon on 09.03.2026.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RadioStation;

NS_ASSUME_NONNULL_BEGIN

@interface RadioStationTag : NSManagedObject

+ (NSFetchRequest<RadioStationTag *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSSet<RadioStation *> *radioStations;

@end

@interface RadioStationTag (CoreDataGeneratedAccessors)

- (void)addRadioStationsObject:(RadioStation *)value;
- (void)removeRadioStationsObject:(RadioStation *)value;
- (void)addRadioStations:(NSSet<RadioStation *> *)values;
- (void)removeRadioStations:(NSSet<RadioStation *> *)values;

@end

NS_ASSUME_NONNULL_END
