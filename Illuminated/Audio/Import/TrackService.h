//
//  TrackService.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "BFTask.h"
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class Track, Playlist;

@interface TrackService : NSObject

+ (BFTask *)importAudioFilesAtURLs:(NSArray<NSURL *> *)filesURLs withPlaylist:(nullable Playlist *)playlist;

+ (BFTask<NSImage *> *)getWaveformForTrack:(Track *)track resolvedURL:(NSURL *)resolvedURL size:(CGSize)size;

+ (BFTask *)importAudioFileAtURL:(NSURL *)fileURL playlist:(nullable Playlist *)playlist;

+ (BFTask *)importAudioFileAtURL:(NSURL *)fileURL bookmarkData:(NSData *)bookmarkData;

+ (BFTask *)analyzeBPMForTrackURL:(NSURL *)trackURL;

+ (BFTask<Track *> *)findOrInsertByURL:(nonnull NSURL *)url playlist:(nullable Playlist *)playlist;

+ (BFTask<Track *> *)findOrInsertByURL:(NSURL *)url bookmarkData:(NSData *)bookmarkData;

@end

NS_ASSUME_NONNULL_END
