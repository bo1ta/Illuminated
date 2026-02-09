//
//  ContentTabViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "ContentTabViewController.h"
#import "MusicViewController.h"
#import "VizualizationViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ContentTabViewController ()
@property(nonatomic, strong) NSTabViewController *tabViewController;
@property(nonatomic, strong) NSTabViewItem *visualizationTabItem;
@property(nonatomic, assign) BOOL hasLoadedVisualizer;
@end

@implementation ContentTabViewController

- (void)loadView {
  self.view = [[NSView alloc] initWithFrame:NSZeroRect];
  self.view.wantsLayer = YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.tabViewController = [[NSTabViewController alloc] init];
  self.tabViewController.tabStyle = NSTabViewControllerTabStyleUnspecified;

  self.musicViewController = [[MusicViewController alloc] initWithNibName:@"MusicViewController" bundle:nil];
  NSTabViewItem *musicItem = [NSTabViewItem tabViewItemWithViewController:self.musicViewController];
  musicItem.label = @"Music";

  NSViewController *placeholderVC = [[NSViewController alloc] init];
  placeholderVC.view = [[NSView alloc] initWithFrame:NSZeroRect];

  self.visualizationTabItem = [NSTabViewItem tabViewItemWithViewController:placeholderVC];
  self.visualizationTabItem.label = @"Vizualizer";

  self.tabViewController.tabViewItems = @[ musicItem, self.visualizationTabItem ];

  [self addChildViewController:self.tabViewController];
  [self.view addSubview:self.tabViewController.view];
  self.tabViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  [NSLayoutConstraint activateConstraints:@[
    [self.tabViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.tabViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.tabViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.tabViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
  ]];

  [self.tabViewController setSelectedTabViewItemIndex:0];
  self.hasLoadedVisualizer = NO;
}

- (void)switchToMusic {
  [self.tabViewController setSelectedTabViewItemIndex:0];
  if (self.hasLoadedVisualizer) {
    [self unloadVisualizer];
  }
}

- (void)switchToVizualizer {
  if (!self.hasLoadedVisualizer) {
    [self loadVisualizer];
  }
  [self.tabViewController setSelectedTabViewItemIndex:1];
}

- (void)loadVisualizer {
  if (self.hasLoadedVisualizer) return;

  NSLog(@"Loading visualizer for the first time...");

  // Create the actual visualizer
  self.vizualizationViewController = [[VizualizationViewController alloc] init];

  // Get the index where the visualizer tab is
  NSInteger visualizerIndex = [self.tabViewController.tabViewItems indexOfObject:self.visualizationTabItem];

  // Remove the placeholder tab
  [self.tabViewController removeTabViewItem:self.visualizationTabItem];

  // Create a new tab item with the real visualizer
  self.visualizationTabItem = [NSTabViewItem tabViewItemWithViewController:self.vizualizationViewController];
  self.visualizationTabItem.label = @"Vizualizer";

  // Insert it back at the same position
  [self.tabViewController insertTabViewItem:self.visualizationTabItem atIndex:visualizerIndex];

  self.hasLoadedVisualizer = YES;

  NSLog(@"Visualizer loaded!");
}

- (void)unloadVisualizer {
  NSLog(@"Unloading visualizer to save resources...");

  // Get the index where the visualizer tab is
  NSInteger visualizerIndex = [self.tabViewController.tabViewItems indexOfObject:self.visualizationTabItem];

  // Destroy the heavy visualizer view controller
  self.vizualizationViewController = nil;

  // Remove the current visualizer tab
  [self.tabViewController removeTabViewItem:self.visualizationTabItem];

  // Create a lightweight placeholder
  NSViewController *placeholderVC = [[NSViewController alloc] init];
  placeholderVC.view = [[NSView alloc] initWithFrame:NSZeroRect];

  // Create new tab item with placeholder
  self.visualizationTabItem = [NSTabViewItem tabViewItemWithViewController:placeholderVC];
  self.visualizationTabItem.label = @"Vizualizer";

  // Insert placeholder back at same position
  [self.tabViewController insertTabViewItem:self.visualizationTabItem atIndex:visualizerIndex];

  self.hasLoadedVisualizer = NO;

  NSLog(@"Visualizer unloaded! Memory freed.");
}

@end

NS_ASSUME_NONNULL_END
