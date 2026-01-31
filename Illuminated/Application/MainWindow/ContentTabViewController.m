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

  self.vizualizationViewController = [[VizualizationViewController alloc] init];
  NSTabViewItem *vizualizationItem = [NSTabViewItem tabViewItemWithViewController:self.vizualizationViewController];
  vizualizationItem.label = @"Vizualizer";

  self.tabViewController.tabViewItems = @[ musicItem, vizualizationItem ];

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
}

- (void)switchToMusic {
  [self.tabViewController setSelectedTabViewItemIndex:0];
}

- (void)switchToVizualizer {
  [self.tabViewController setSelectedTabViewItemIndex:1];
}

@end

NS_ASSUME_NONNULL_END
