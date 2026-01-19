//
//  MainWindowController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "MainWindowController.h"
#import "MainViewController.h"

@interface MainWindowController ()
@property (strong) MainViewController *mainViewController;
@end

@implementation MainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    [self.window.contentView addSubview:self.mainViewController.view];
    
    self.mainViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.mainViewController.view.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor],
        [self.mainViewController.view.bottomAnchor constraintEqualToAnchor:self.window.contentView.bottomAnchor],
        [self.mainViewController.view.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor],
        [self.mainViewController.view.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor]
    ]];
}

@end
