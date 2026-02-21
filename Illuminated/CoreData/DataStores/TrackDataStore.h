//
//  TrackDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "BFGeneric.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Track, Artist, Album;
@class NSManagedObjectContext, NSFetchedResultsController, NSManagedObjectID;
@class BFTask<__covariant ResultType>;

@interface TrackDataStore : NSObject

+ (BFTask<BFVoid> *)incrementPlayCountForTrack:(Track *)track;

+ (Track *)insertTrackWithTitle:(NSString *)title
                        fileURL:(NSString *)fileURL
                    urlBookmark:(nullable NSData *)urlBookmark
                    trackNumber:(int16_t)trackNumber
                       fileType:(nullable NSString *)fileType
                        bitrate:(int16_t)bitrate
                     sampleRate:(int16_t)sampleRate
                       duration:(double)duration
                            bpm:(float)bpm
                         artist:(nullable Artist *)artist
                          album:(nullable Album *)album
                      inContext:(NSManagedObjectContext *)context;

+ (BFTask<Track *> *)trackWithURL:(NSURL *)url;

+ (NSFetchedResultsController *)fetchedResultsController;

+ (BFTask *)deleteTrackWithObjectID:(NSManagedObjectID *)trackObjectID;

+ (BFTask *)updateTrackWithObjectID:(NSManagedObjectID *)trackObjectID
                          withTitle:(NSString *)title
                         artistName:(NSString *)artistName
                         albumTitle:(NSString *)albumTitle
                   albumArtworkPath:(nullable NSString *)albumArtworkPath
                              genre:(NSString *)genre
                               year:(uint16_t)year;

@end

NS_ASSUME_NONNULL_END
