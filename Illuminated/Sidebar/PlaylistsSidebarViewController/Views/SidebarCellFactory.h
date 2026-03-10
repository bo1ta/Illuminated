//
//  SidebarCellFactory.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString *SidebarCellType NS_STRING_ENUM;
static SidebarCellType const SidebarCellTypeHeader = @"SidebarCellHeader";
static SidebarCellType const SidebarCellTypeItem = @"SidebarCellItem";

@interface SidebarCellFactory : NSObject

+ (NSTableCellView *)itemCellForOutlineView:(NSOutlineView *)outlineView
                                      title:(NSString *)title
                                 systemIcon:(nullable NSString *)systemIcon;
+ (NSTableCellView *)headerCellForOutlineView:(NSOutlineView *)outlineView title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
