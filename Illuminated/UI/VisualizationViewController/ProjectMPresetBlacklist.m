//
//  ProjectMPresetBlacklist.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import <Foundation/Foundation.h>
#import "ProjectMPresetBlacklist.h"

NSString *const UserDefaultsBlacklistKey = @"BlacklistedPresets";

@interface ProjectMPresetBlacklist ()

@end

@implementation ProjectMPresetBlacklist

- (instancetype)init {
  self = [super init];
  if (self) {
    [self loadBlacklist];
  }
  return self;
}

- (NSUserDefaults *)userDefaults {
  return [NSUserDefaults standardUserDefaults];
}

- (void)loadBlacklist {
  NSArray *saved = [[self userDefaults] arrayForKey:UserDefaultsBlacklistKey];
  _blacklist = saved ? [saved mutableCopy] : [NSMutableArray array];
}

- (BOOL)isBlacklisted:(NSString *)presetPath {
    return [self.blacklist containsObject:presetPath];
}

- (void)addToBlacklist:(NSString *)presetPath {
    if (!presetPath || [self isBlacklisted:presetPath]) return;
    
    [self.blacklist addObject:presetPath];
    [[self userDefaults] setObject:[self.blacklist copy] forKey:UserDefaultsBlacklistKey];
}

- (void)filterPlaylist:(projectm_playlist_handle)playlistHandle {
  if (!playlistHandle || self.blacklist.count == 0) return;
  
  uint32_t size = projectm_playlist_size(playlistHandle);
  for (int i = size - 1; i >= 0; i--) {
    const char *presetPath = projectm_playlist_item(playlistHandle, i);
    NSString *presetPathStr = [NSString stringWithUTF8String:presetPath];
    if (presetPathStr && [self isBlacklisted:presetPathStr]) {
      projectm_playlist_remove_preset(playlistHandle, i);
    }
  }
}

@end
