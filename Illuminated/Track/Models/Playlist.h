//
//  Playlist.h
//
//
//  Created by Alexandru Solomon on 18.01.2026.
//
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class Track;

NS_ASSUME_NONNULL_BEGIN

@interface Playlist : NSManagedObject

+ (NSFetchRequest<Playlist *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property(nullable, nonatomic, copy) NSUUID *uniqueID;
@property(nullable, nonatomic, copy) NSString *name;
@property(nonatomic) BOOL isSmart;
@property(nullable, nonatomic, copy) NSString *iconName;
@property(nullable, nonatomic, retain) NSSet<Track *> *tracks;

@end

@interface Playlist (CoreDataGeneratedAccessors)

- (void)addTracksObject:(Track *)value;
- (void)removeTracksObject:(Track *)value;
- (void)addTracks:(NSSet<Track *> *)values;
- (void)removeTracks:(NSSet<Track *> *)values;

@end

NS_ASSUME_NONNULL_END
