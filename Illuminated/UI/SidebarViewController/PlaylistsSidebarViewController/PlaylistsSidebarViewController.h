//
//  SidebarViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 19.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SidebarSelectionItemDidChange;
extern NSString *const PasteboardItemTypeTrack;

@class PlaylistsSidebarViewController;

@interface PlaylistsSidebarViewController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>

@property(weak) IBOutlet NSOutlineView *outlineView;

@end

NS_ASSUME_NONNULL_END
