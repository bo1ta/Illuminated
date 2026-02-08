//
//  SidebarContainerViewController.h
//  Illuminated
//
//  Created by Codex on 08.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SidebarViewController;
@class FileBrowserViewController;

@interface SidebarContainerViewController : NSViewController

@property(nonatomic, strong, readonly) SidebarViewController *libraryViewController;
@property(nonatomic, strong, readonly) FileBrowserViewController *fileBrowserViewController;

@end

NS_ASSUME_NONNULL_END
