//
//  SidebarViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 19.01.2026.
//

#import <Cocoa/Cocoa.h>
#import "SidebarCellFactory.h"
#import "SidebarDataSource.h"
#import "SidebarItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface SidebarViewController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property(weak) IBOutlet NSOutlineView *outlineView;
@property(strong, nonatomic) NSArray<SidebarItem *> *sidebarItems;
@end

NS_ASSUME_NONNULL_END
