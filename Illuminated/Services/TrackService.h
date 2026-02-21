//
//  TrackService.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class Track, Playlist;

@class BFTask<__covariant ResultType>;

@interface TrackService : NSObject

+ (BFTask *)importAudioFilesAtURLs:(NSArray<NSURL *> *)filesURLs withPlaylist:(nullable Playlist *)playlist;

+ (BFTask<NSImage *> *)getWaveformForTrack:(Track *)track resolvedURL:(NSURL *)resolvedURL size:(CGSize)size;

+ (BFTask *)importAudioFileAtURL:(NSURL *)fileURL playlist:(nullable Playlist *)playlist;

+ (BFTask *)importAudioFileAtURL:(NSURL *)fileURL bookmarkData:(NSData *)bookmarkData;

+ (BFTask *)analyzeBPMForTrackURL:(NSURL *)trackURL;

+ (BFTask<Track *> *)findOrInsertByURL:(nonnull NSURL *)url playlist:(nullable Playlist *)playlist;

+ (BFTask<Track *> *)findOrInsertByURL:(NSURL *)url bookmarkData:(NSData *)bookmarkData;

+ (NSURL *)resolveTrackURL:(Track *)track;

+ (BFTask *)deleteTrack:(Track *)track;

+ (BFTask *)deleteTracks:(NSArray<Track *> *)tracks;

+ (NSImage *)loadArtworkForTrack:(Track *)track withPlaceholderSize:(CGSize)size;

+ (BFTask *)updateTrack:(Track *)track
              withTitle:(NSString *)title
             artistName:(NSString *)artistName
             albumTitle:(NSString *)albumTitle
             albumImage:(nullable NSImage *)albumImage
                  genre:(NSString *)genre
                   year:(uint16_t)year;

@end

NS_ASSUME_NONNULL_END
