//
//  WriteOnlyStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <Foundation/Foundation.h>
#import "Album.h"
#import "Artist.h"
#import "BFTask.h"
#import "Playlist.h"
#import "Track.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSManagedObject *_Nullable (^WriteBlock)(NSManagedObjectContext *context, NSError **error);

@protocol WriteOnlyStore <NSObject>

- (BFTask<NSManagedObjectID *> *)performWrite:(WriteBlock)writeBlock;

- (BFTask<NSManagedObjectID *> *)createAlbumWithTitle:(NSString *)title
                                                 year:(nullable NSNumber *)year
                                          artworkPath:(nullable NSString *)artworkPath
                                             duration:(double)duration
                                                genre:(nullable NSString *)genre;

- (BFTask<NSManagedObjectID *> *)createArtistWithName:(NSString *)name;

- (BFTask<NSManagedObjectID *> *)createTrackWithTitle:(nullable NSString *)title
                                          trackNumber:(int16_t)trackNumber
                                              fileURL:(nullable NSString *)fileURL
                                             fileType:(nullable NSString *)fileType
                                              bitrate:(int16_t)bitrate
                                           sampleRate:(int16_t)sampleRate
                                             duration:(double)duration;

@end

NS_ASSUME_NONNULL_END
