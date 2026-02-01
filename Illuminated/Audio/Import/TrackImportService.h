//
//  TrackImportService.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "BFExecutor.h"
#import "BFTaskCompletionSource.h"
#import "CoreDataStore.h"
#import "NSManagedObjectContext+Helpers.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Track, Playlist;

@interface TrackImportService : NSObject

- (BFTask *)importAudioFilesAtURLs:(NSArray<NSURL *> *)filesURLs withPlaylist:(nullable Playlist *)playlist;

- (BFTask *)importAudioFileAtURL:(NSURL *)fileURL withPlaylist:(nullable Playlist *)playlist;

- (BFTask *)analyzeBPMForTrackURL:(NSURL *)trackURL;

@end

NS_ASSUME_NONNULL_END
