//
//  RadioStation+CoreDataClass.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RadioStationTag;

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
@property (nullable, nonatomic, copy) NSNumber *clickCount;
@property (nullable, nonatomic, copy) NSString *favicon;
@property (nullable, nonatomic, copy) NSString *homepage;
@property (nullable, nonatomic, copy) NSString *serverIDFallback;
@property (nonatomic) BOOL isFavorite;
@property (nullable, nonatomic, retain) NSSet<RadioStationTag *> *tags;

@end

@interface RadioStation (CoreDataGeneratedAccessors)

- (void)addTagsObject:(RadioStationTag *)value;
- (void)removeTagsObject:(RadioStationTag *)value;
- (void)addTags:(NSSet<RadioStationTag *> *)values;
- (void)removeTags:(NSSet<RadioStationTag *> *)values;

@end

NS_ASSUME_NONNULL_END
