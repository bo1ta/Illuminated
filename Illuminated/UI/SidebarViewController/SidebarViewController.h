//
//  SidebarViewController.h
//  Illuminated
//
//  Created by Codex on 08.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class PlaylistsSidebarViewController;
@class FilesSidebarViewController;

@interface SidebarViewController : NSViewController

@property(nonatomic, strong, readonly) PlaylistsSidebarViewController *libraryViewController;
@property(nonatomic, strong, readonly) FilesSidebarViewController *fileBrowserViewController;

@end

NS_ASSUME_NONNULL_END
