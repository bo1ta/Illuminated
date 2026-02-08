//
//  TrackImportService.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Foundation/Foundation.h>
#import "BFTask.h"

NS_ASSUME_NONNULL_BEGIN

@class Track, Playlist;

@interface TrackImportService : NSObject

+ (BFTask *)importAudioFilesAtURLs:(NSArray<NSURL *> *)filesURLs withPlaylist:(nullable Playlist *)playlist;

+ (BFTask *)importAudioFileAtURL:(NSURL *)fileURL playlist:(nullable Playlist *)playlist;

+ (BFTask *)importAudioFileAtURL:(NSURL *)fileURL bookmarkData:(NSData *)bookmarkData;

+ (BFTask *)analyzeBPMForTrackURL:(NSURL *)trackURL;

@end

NS_ASSUME_NONNULL_END
