//
//  Artist.h
//
//
//  Created by Alexandru Solomon on 18.01.2026.
//
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class Album, Track;

NS_ASSUME_NONNULL_BEGIN

@interface Artist : NSManagedObject

+ (NSFetchRequest<Artist *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property(nullable, nonatomic, copy) NSUUID *uniqueID;
@property(nullable, nonatomic, copy) NSString *name;
@property(nullable, nonatomic, retain) NSSet<Album *> *albums;
@property(nullable, nonatomic, retain) NSSet<Track *> *tracks;

@end

@interface Artist (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(Album *)value;
- (void)removeAlbumsObject:(Album *)value;
- (void)addAlbums:(NSSet<Album *> *)values;
- (void)removeAlbums:(NSSet<Album *> *)values;

- (void)addTracksObject:(Track *)value;
- (void)removeTracksObject:(Track *)value;
- (void)addTracks:(NSSet<Track *> *)values;
- (void)removeTracks:(NSSet<Track *> *)values;

@end

NS_ASSUME_NONNULL_END
