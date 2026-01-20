//
//  WriteOnlyStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "Album.h"
#import "Artist.h"
#import "BFTask.h"
#import "Playlist.h"
#import "Track.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^WriteBlock)(NSManagedObjectContext *_Nonnull context, NSError *_Nullable *_Nullable error);

@protocol WriteOnlyStore<NSObject>

- (BFTask *)performWrite:(WriteBlock)writeBlock;

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

@end

NS_ASSUME_NONNULL_END
