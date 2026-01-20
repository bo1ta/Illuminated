//
//  Track.h
//
//
//  Created by Alexandru Solomon on 18.01.2026.
//
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class Album, Artist, Playlist;

NS_ASSUME_NONNULL_BEGIN

@interface Track : NSManagedObject

+ (NSFetchRequest<Track *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property(nullable, nonatomic, copy) NSUUID *uniqueID;
@property(nullable, nonatomic, copy) NSString *title;
@property(nonatomic) double duration;
@property(nonatomic) int16_t trackNumber;
@property(nonatomic) int16_t discNumber;
@property(nullable, nonatomic, copy) NSString *fileURL;
@property(nullable, nonatomic, copy) NSString *fileType;
@property(nonatomic) int16_t bitrate;
@property(nonatomic) int16_t sampleRate;
@property(nonatomic) int16_t playCount;
@property(nullable, nonatomic, copy) NSDate *lastPlayed;
@property(nonatomic) int16_t rating;
@property(nullable, nonatomic, copy) NSString *genre;
@property(nullable, nonatomic, copy) NSString *lyrics;
@property(nonatomic) int16_t year;
@property(nullable, nonatomic, retain) Album *album;
@property(nullable, nonatomic, retain) Artist *artist;
@property(nullable, nonatomic, retain) NSSet<Playlist *> *playlists;

@end

@interface Track (CoreDataGeneratedAccessors)

- (void)addPlaylistsObject:(Playlist *)value;
- (void)removePlaylistsObject:(Playlist *)value;
- (void)addPlaylists:(NSSet<Playlist *> *)values;
- (void)removePlaylists:(NSSet<Playlist *> *)values;

@end

NS_ASSUME_NONNULL_END
