//
//  SidebarItem.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "PlaylistSidebarItem.h"
#import <Foundation/Foundation.h>

@implementation PlaylistSidebarItem

- (instancetype)initWithType:(SidebarItemType)type
                       title:(NSString *)title
                    iconName:(nullable NSString *)iconName
                    children:(nullable NSArray<PlaylistSidebarItem *> *)children {
  self = [super init];
  if (self) {
    _type = type;
    _title = [title copy];
    _iconName = [iconName copy];
    _children = [children copy];
  }
  return self;
}

+ (instancetype)groupWithTitle:(NSString *)title children:(NSArray<PlaylistSidebarItem *> *)children {
  return [[self alloc] initWithType:SidebarItemTypeGroup title:title iconName:nil children:children];
}

+ (instancetype)itemWithTitle:(NSString *)title iconName:(nullable NSString *)iconName {
  return [[self alloc] initWithType:SidebarItemTypeItem title:title iconName:iconName children:nil];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p; type=%ld; title=%@; icon=%@; children=%@>",
                                    NSStringFromClass([self class]),
                                    self,
                                    (long)_type,
                                    _title,
                                    _iconName ?: @"nil",
                                    _children ? @(_children.count) : @"nil"];
}

@end
