//
//  WriteOnlyStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "BFTask.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Track, Album, Playlist, Artist;

typedef id _Nullable (^WriteBlock)(NSManagedObjectContext *context);

@protocol WriteOnlyStore<NSObject>

- (BFTask *)performWrite:(WriteBlock)writeBlock;

- (BFTask *)deleteObjectWithEntityName:(NSString *)entityName uniqueID:(NSUUID *)uniqueID;

- (BFTask *)createAlbumWithTitle:(NSString *)title
                            year:(nullable NSNumber *)year
                     artworkPath:(nullable NSString *)artworkPath
                        duration:(double)duration
                           genre:(nullable NSString *)genre;

- (BFTask *)createArtistWithName:(NSString *)name;

- (BFTask *)createTrackWithTitle:(nullable NSString *)title
                     trackNumber:(int16_t)trackNumber
                         fileURL:(nullable NSString *)fileURL
                        fileType:(nullable NSString *)fileType
                         bitrate:(int16_t)bitrate
                      sampleRate:(int16_t)sampleRate
                        duration:(double)duration;
- (BFTask *)incrementPlayCountForTrack:(Track *)track;

@end

NS_ASSUME_NONNULL_END
