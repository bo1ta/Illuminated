//
//  SidebarViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 19.01.2026.
//

#import "SidebarCellFactory.h"
#import "SidebarDataSource.h"
#import "SidebarItem.h"
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SidebarSelectionItemDidChange;

@class SidebarViewController;

@interface SidebarViewController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property(weak) IBOutlet NSOutlineView *outlineView;

@end

NS_ASSUME_NONNULL_END
