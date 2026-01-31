//
//  MainWindowController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "MainWindowController.h"
#import "ContentTabViewController.h"
#import "MusicViewController.h"
#import "PlayerBarViewController.h"
#import "SidebarViewController.h"

NSString *const ToolbarSearchDidChangeNotification = @"ToolbarSearchDidChangeNotification";
NSString *const ToolbarSearchUserInfo = @"ToolbarSearch";

@interface MainWindowController ()<NSToolbarDelegate, NSSearchFieldDelegate>

@property(strong) MusicViewController *musicViewController;
@property(strong) PlayerBarViewController *playerBarViewController;
@property(strong) NSSplitViewController *splitViewController;
@property(nonatomic, strong) NSSearchField *searchField;
@property(nonatomic, strong) ContentTabViewController *contentTabViewController;

@property(nonatomic, strong) NSSegmentedControl *tabSegmentedControl;

@end

@implementation MainWindowController

- (void)windowDidLoad {
  [super windowDidLoad];

  [self setupToolbar];

  self.splitViewController = [[NSSplitViewController alloc] init];

  SidebarViewController *sidebarVC = [[SidebarViewController alloc] init];
  NSSplitViewItem *sidebarItem = [NSSplitViewItem sidebarWithViewController:sidebarVC];
  sidebarItem.canCollapse = YES;
  sidebarItem.minimumThickness = 180;
  sidebarItem.maximumThickness = 300;
  [self.splitViewController addSplitViewItem:sidebarItem];

  //  self.musicViewController = [[MusicViewController alloc] initWithNibName:@"MusicViewController" bundle:nil];
  //
  //  NSSplitViewItem *contentItem = [NSSplitViewItem splitViewItemWithViewController:self.musicViewController];
  //  contentItem.minimumThickness = 400;
  //  [self.splitViewController addSplitViewItem:contentItem];

  ContentTabViewController *contentTabVC = [[ContentTabViewController alloc] init];
  NSSplitViewItem *contentItem = [NSSplitViewItem splitViewItemWithViewController:contentTabVC];
  contentItem.minimumThickness = 400;
  [self.splitViewController addSplitViewItem:contentItem];

  self.contentTabViewController = contentTabVC;

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
    [self.playerBarViewController.view.heightAnchor constraintEqualToConstant:130]
  ]];

  // Set container as window content
  self.window.contentViewController = containerVC;
}

- (void)setupToolbar {
  NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"MainToolbar"];
  toolbar.delegate = self;
  toolbar.displayMode = NSToolbarDisplayModeIconOnly;
  self.window.toolbar = toolbar;
  self.window.titleVisibility = NSWindowTitleHidden;
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  return
      @[ NSToolbarFlexibleSpaceItemIdentifier, @"TabSwitcher", NSToolbarFlexibleSpaceItemIdentifier, @"SearchField" ];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return
      @[ NSToolbarFlexibleSpaceItemIdentifier, @"TabSwitcher", NSToolbarFlexibleSpaceItemIdentifier, @"SearchField" ];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
        itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag {

  if ([itemIdentifier isEqualToString:@"SearchField"]) {
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    self.searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(0, 0, 200, 22)];
    self.searchField.placeholderString = @"Search";
    self.searchField.delegate = self;
    self.searchField.target = self;
    self.searchField.action = @selector(searchFieldDidChange:);

    item.view = self.searchField;
    item.label = @"Search";

    return item;
  } else if ([itemIdentifier isEqualToString:@"TabSwitcher"]) {
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    self.tabSegmentedControl = [[NSSegmentedControl alloc] initWithFrame:NSMakeRect(0, 0, 220, 24)];
    [self.tabSegmentedControl setSegmentCount:2];
    [self.tabSegmentedControl setLabel:@"Music" forSegment:0];
    [self.tabSegmentedControl setLabel:@"Visualizer" forSegment:1];
    [self.tabSegmentedControl setSelectedSegment:0]; // start on Music
    self.tabSegmentedControl.target = self;
    self.tabSegmentedControl.action = @selector(tabSegmentChanged:);

    // Optional: make it look nicer
    self.tabSegmentedControl.segmentDistribution = NSSegmentDistributionFit;
    // self.tabSegmentedControl.segmentStyle = NSSegmentStyleRounded; // macOS 14+

    item.view = self.tabSegmentedControl;
    item.label = @"View Mode";

    return item;
  }

  return nil;
}

- (void)tabSegmentChanged:(NSSegmentedControl *)sender {
  NSInteger index = sender.selectedSegment;
  if (index == 0) {
    [self.contentTabViewController switchToMusic];
  } else {
    [self.contentTabViewController switchToVizualizer];
  }
  
  [self.splitViewController toggleSidebar:self];
}

#pragma mark - Search

- (void)searchFieldDidChange:(NSSearchField *)sender {
  NSString *searchText = sender.stringValue;
  [[NSNotificationCenter defaultCenter] postNotificationName:ToolbarSearchDidChangeNotification
                                                      object:nil
                                                    userInfo:@{ToolbarSearchUserInfo : searchText}];
}
@end
