//
//  MainWindowController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "MainWindowController.h"
#import "MusicViewController.h"
#import "PlayerBarViewController.h"
#import "SidebarViewController.h"

@interface MainWindowController ()<MusicViewControllerDelegate>

@property(strong) MusicViewController *musicViewController;
@property(strong) PlayerBarViewController *playerBarViewController;
@property(strong) NSSplitViewController *splitViewController;

@end

@implementation MainWindowController

- (void)windowDidLoad {
  [super windowDidLoad];

  self.splitViewController = [[NSSplitViewController alloc] init];

  SidebarViewController *sidebarVC = [[SidebarViewController alloc] init];
  NSSplitViewItem *sidebarItem = [NSSplitViewItem sidebarWithViewController:sidebarVC];
  sidebarItem.canCollapse = YES;
  sidebarItem.minimumThickness = 180;
  sidebarItem.maximumThickness = 300;
  [self.splitViewController addSplitViewItem:sidebarItem];

  self.musicViewController = [[MusicViewController alloc] initWithNibName:@"MusicViewController" bundle:nil];
  self.musicViewController.delegate = self;

  NSSplitViewItem *contentItem = [NSSplitViewItem splitViewItemWithViewController:self.musicViewController];
  contentItem.minimumThickness = 400;
  [self.splitViewController addSplitViewItem:contentItem];

  // Force split view to load its view
  [self.splitViewController loadView];
  [self.splitViewController viewDidLoad];

  // Create container view controller
  NSViewController *containerVC = [[NSViewController alloc] init];
  containerVC.view = [[NSView alloc] initWithFrame:self.window.contentView.bounds];

  // Add split view to container
  [containerVC addChildViewController:self.splitViewController];
  [containerVC.view addSubview:self.splitViewController.view];

  // Create and add player bar
  self.playerBarViewController = [[PlayerBarViewController alloc] init];
  [containerVC addChildViewController:self.playerBarViewController];
  [containerVC.view addSubview:self.playerBarViewController.view];

  // Setup Auto Layout
  self.splitViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.playerBarViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  [NSLayoutConstraint activateConstraints:@[
    // Split view - top to player bar
    [self.splitViewController.view.topAnchor constraintEqualToAnchor:containerVC.view.topAnchor],
    [self.splitViewController.view.leadingAnchor constraintEqualToAnchor:containerVC.view.leadingAnchor],
    [self.splitViewController.view.trailingAnchor constraintEqualToAnchor:containerVC.view.trailingAnchor],
    [self.splitViewController.view.bottomAnchor constraintEqualToAnchor:self.playerBarViewController.view.topAnchor],

    // Player bar - bottom, fixed height
    [self.playerBarViewController.view.leadingAnchor constraintEqualToAnchor:containerVC.view.leadingAnchor],
    [self.playerBarViewController.view.trailingAnchor constraintEqualToAnchor:containerVC.view.trailingAnchor],
    [self.playerBarViewController.view.bottomAnchor constraintEqualToAnchor:containerVC.view.bottomAnchor],
    [self.playerBarViewController.view.heightAnchor constraintEqualToConstant:80]
  ]];

  // Set container as window content
  self.window.contentViewController = containerVC;
}

- (void)trackSelected:(NSNotification *)notification {
  Track *track = notification.object;
  self.playerBarViewController.currentTrack = track;
  [self.playerBarViewController play];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - MusicViewControllerDelegate

- (void)musicViewController:(MusicViewController *)controller didSelectTrack:(Track *)track {
  [self.playerBarViewController setCurrentTrack:track];
}

@end
