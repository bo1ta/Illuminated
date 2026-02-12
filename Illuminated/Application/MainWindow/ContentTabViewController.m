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

  self.vizualizationViewController = [[VizualizationViewController alloc] init];
  NSInteger visualizerIndex = [self.tabViewController.tabViewItems indexOfObject:self.visualizationTabItem];

  [self.tabViewController removeTabViewItem:self.visualizationTabItem];

  self.visualizationTabItem = [NSTabViewItem tabViewItemWithViewController:self.vizualizationViewController];
  self.visualizationTabItem.label = @"Vizualizer";

  // Insert it back at the same position
  [self.tabViewController insertTabViewItem:self.visualizationTabItem atIndex:visualizerIndex];

  self.hasLoadedVisualizer = YES;
}

- (void)unloadVisualizer {
  NSInteger visualizerIndex = [self.tabViewController.tabViewItems indexOfObject:self.visualizationTabItem];

  self.vizualizationViewController = nil;

  [self.tabViewController removeTabViewItem:self.visualizationTabItem];

  NSViewController *placeholderVC = [[NSViewController alloc] init];
  placeholderVC.view = [[NSView alloc] initWithFrame:NSZeroRect];

  self.visualizationTabItem = [NSTabViewItem tabViewItemWithViewController:placeholderVC];
  self.visualizationTabItem.label = @"Vizualizer";

  [self.tabViewController insertTabViewItem:self.visualizationTabItem atIndex:visualizerIndex];

  self.hasLoadedVisualizer = NO;
}

@end

NS_ASSUME_NONNULL_END
