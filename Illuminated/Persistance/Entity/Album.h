//
//  Album.h
//  
//
//  Created by Alexandru Solomon on 18.01.2026.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artist, Track;

NS_ASSUME_NONNULL_BEGIN

@interface Album : NSManagedObject

+ (NSFetchRequest<Album *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSUUID *uniqueID;
@property (nullable, nonatomic, copy) NSString *title;
@property (nonatomic) int16_t year;
@property (nullable, nonatomic, copy) NSString *artworkPath;
@property (nonatomic) double duration;
@property (nullable, nonatomic, copy) NSString *genre;
@property (nullable, nonatomic, retain) NSSet<Track *> *tracks;
@property (nullable, nonatomic, retain) Artist *artist;

@end

@interface Album (CoreDataGeneratedAccessors)

- (void)addTracksObject:(Track *)value;
- (void)removeTracksObject:(Track *)value;
- (void)addTracks:(NSSet<Track *> *)values;
- (void)removeTracks:(NSSet<Track *> *)values;

@end

NS_ASSUME_NONNULL_END
