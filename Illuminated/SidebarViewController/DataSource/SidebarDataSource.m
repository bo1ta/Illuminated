//
//  SidebarDataSource.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Foundation/Foundation.h>

#import "SidebarDataSource.h"
#import "SidebarItem.h"

@implementation SidebarDataSource

- (instancetype)init {
  self = [super init];
  if (self) {
    _items = [self buildDefaultItems];
  }
  return self;
}

+ (instancetype)sharedDataSource {
  static SidebarDataSource *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ sharedInstance = [[self alloc] init]; });
  return sharedInstance;
}

- (NSArray<SidebarItem *> *)buildDefaultItems {
  return @[
    [SidebarItem groupWithTitle:@"Library"
                       children:@[
                         [SidebarItem itemWithTitle:@"Music" iconName:@"music.note"],
                         [SidebarItem itemWithTitle:@"Movies" iconName:@"film"],
                         [SidebarItem itemWithTitle:@"TV Shows" iconName:@"tv"]
                       ]],

    [SidebarItem groupWithTitle:@"Playlists"
                       children:@[
                         [SidebarItem itemWithTitle:@"My Top Played" iconName:@"star.fill"],
                         [SidebarItem itemWithTitle:@"Recently Added" iconName:@"clock"],
                         [SidebarItem itemWithTitle:@"Chill Vibes" iconName:@"music.note.list"],
                         [SidebarItem itemWithTitle:@"Classic Rock" iconName:@"guitars"]
                       ]],
  ];
}

- (void)reloadData {
  // Could load from disk, network, etc.
  _items = [self buildDefaultItems];
}

@end
