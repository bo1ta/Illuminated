//
//  TrackDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "BFTask.h"
#import <Foundation/Foundation.h>

@class Track, Artist, Album, NSManagedObjectContext;

NS_ASSUME_NONNULL_BEGIN

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

@end

NS_ASSUME_NONNULL_END
