//
//  ProjectMPresetBlacklist.h
//  Illuminated
//
//  Created by Alexandru Solomon on 13.02.2026.
//

#import <Cocoa/Cocoa.h>
#import <projectM-4/playlist.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProjectMPresetBlacklist : NSObject

@property (readonly, nonatomic, strong) NSMutableArray<NSString *> *blacklist;

- (BOOL)isBlacklisted:(NSString *)presetPath;

- (void)addToBlacklist:(NSString *)presetPath;

- (void)filterPlaylist:(projectm_playlist_handle)playlistHandle;

@end

NS_ASSUME_NONNULL_END
