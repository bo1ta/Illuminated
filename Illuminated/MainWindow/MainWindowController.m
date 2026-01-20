//
//  MainWindowController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "MainWindowController.h"
#import "MainViewController.h"
#import "SidebarViewController.h"

@interface MainWindowController ()
@property(strong) MainViewController *mainViewController;
@property(strong) NSSplitViewController *splitViewController;
@end

@implementation MainWindowController

- (void)windowDidLoad {
  [super windowDidLoad];

  self.splitViewController = [[NSSplitViewController alloc] init];

  SidebarViewController *sidebarVC = [[SidebarViewController alloc] init];
  NSSplitViewItem *sidebarItem = [NSSplitViewItem sidebarWithViewController:sidebarVC];
  sidebarItem.canCollapse = YES;  // Optional: allows collapsing
  sidebarItem.minimumThickness = 180;
  sidebarItem.maximumThickness = 300;
  [self.splitViewController addSplitViewItem:sidebarItem];

  self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController"
                                                                 bundle:nil];
  NSSplitViewItem *contentItem =
      [NSSplitViewItem splitViewItemWithViewController:self.mainViewController];
  contentItem.minimumThickness = 400;  // Optional: set minimum width for main content
  [self.splitViewController addSplitViewItem:contentItem];

  self.window.contentViewController = self.splitViewController;
}

@end
