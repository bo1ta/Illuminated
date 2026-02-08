//
//  TrackDataStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "BFTask.h"
#import <Foundation/Foundation.h>

@class Track, Playlist;

NS_ASSUME_NONNULL_BEGIN

@interface TrackDataStore : NSObject

+ (BFTask<Track *> *)findOrInsertByURL:(NSURL *)url;

+ (BFTask<Track *> *)findOrInsertByURL:(NSURL *)url
                          bookmarkData:(NSData *)bookmarkData;

+ (BFTask<Track *> *)findOrInsertByURL:(nonnull NSURL *)url
                              playlist:(Playlist *)playlist;

+ (BFTask *)importTracksFromAudioURLs:(NSArray<NSURL *> *)audioURLs
                             playlist:(Playlist *)playlist;

@end

NS_ASSUME_NONNULL_END
