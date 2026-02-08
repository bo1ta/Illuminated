//
//  SidebarContainerViewController.m
//  Illuminated
//
//  Created by Codex on 08.02.2026.
//

#import "SidebarContainerViewController.h"
#import "FileBrowserViewController.h"
#import "SidebarViewController.h"

@interface SidebarContainerViewController ()

@property(nonatomic, strong) NSSegmentedControl *switcher;
@property(nonatomic, strong) NSView *contentView;
@property(nonatomic, strong, readwrite) SidebarViewController *libraryViewController;
@property(nonatomic, strong, readwrite) FileBrowserViewController *fileBrowserViewController;
@property(nonatomic, strong) NSViewController *currentChild;

@end

@implementation SidebarContainerViewController

- (void)loadView {
  NSView *baseView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 220, 400)];
  baseView.translatesAutoresizingMaskIntoConstraints = NO;
  self.view = baseView;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self setupControllers];
  [self setupSwitcher];
  [self setupContentContainer];
  [self switchToIndex:0];
}

- (void)setupControllers {
  self.libraryViewController = [[SidebarViewController alloc] init];
  self.fileBrowserViewController = [[FileBrowserViewController alloc] init];
}

- (void)setupSwitcher {
  self.switcher = [[NSSegmentedControl alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
  self.switcher.segmentCount = 2;
  [self.switcher setLabel:@"Library" forSegment:0];
  [self.switcher setLabel:@"Files" forSegment:1];
  self.switcher.selectedSegment = 0;
  self.switcher.segmentDistribution = NSSegmentDistributionFillEqually;
  self.switcher.target = self;
  self.switcher.action = @selector(switcherChanged:);
  self.switcher.translatesAutoresizingMaskIntoConstraints = NO;

  [self.view addSubview:self.switcher];
}

- (void)setupContentContainer {
  self.contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 220, 400)];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.contentView];

  [NSLayoutConstraint activateConstraints:@[
    [self.switcher.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:8],
    [self.switcher.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:8],
    [self.switcher.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8],

    [self.contentView.topAnchor constraintEqualToAnchor:self.switcher.bottomAnchor constant:8],
    [self.contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];
}

- (void)switcherChanged:(NSSegmentedControl *)sender {
  [self switchToIndex:sender.selectedSegment];
}

- (void)switchToIndex:(NSInteger)index {
  NSViewController *target = (index == 0) ? self.libraryViewController : self.fileBrowserViewController;
  if (self.currentChild == target) return;

  if (self.currentChild) {
    [self.currentChild.view removeFromSuperview];
    [self.currentChild removeFromParentViewController];
  }

  self.currentChild = target;
  [self addChildViewController:target];
  target.view.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:target.view];

  [NSLayoutConstraint activateConstraints:@[
    [target.view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [target.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
    [target.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
    [target.view.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
  ]];
}

@end
