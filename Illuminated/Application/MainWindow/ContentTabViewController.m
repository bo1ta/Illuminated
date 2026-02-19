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

  self.musicViewController = [[MusicViewController alloc] initWithNibName:@"MusicViewController" bundle:nil];

  [self addChildViewController:self.musicViewController];
  [self.view addSubview:self.musicViewController.view];
  self.musicViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  [NSLayoutConstraint activateConstraints:@[
    [self.musicViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.musicViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.musicViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.musicViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
  ]];
}

- (void)switchToMusic {
  if (self.musicViewController.view.superview) return;

  if (self.vizualizationViewController) {
    [self.vizualizationViewController.view removeFromSuperview];
    [self.vizualizationViewController removeFromParentViewController];
    self.vizualizationViewController = nil;
  }

  [self addChildViewController:self.musicViewController];
  [self.view addSubview:self.musicViewController.view];
  self.musicViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  [NSLayoutConstraint activateConstraints:@[
    [self.musicViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.musicViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.musicViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.musicViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
  ]];
}

- (void)switchToVizualizer {
  if (self.vizualizationViewController.view.superview) return;

  [self.musicViewController.view removeFromSuperview];
  [self.musicViewController removeFromParentViewController];

  self.vizualizationViewController = [[VizualizationViewController alloc] init];
  [self addChildViewController:self.vizualizationViewController];
  [self.view addSubview:self.vizualizationViewController.view];
  self.vizualizationViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  [NSLayoutConstraint activateConstraints:@[
    [self.vizualizationViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.vizualizationViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.vizualizationViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.vizualizationViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
  ]];
}

@end

NS_ASSUME_NONNULL_END
