//
//  SidebarViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 19.01.2026.
//

#import "SidebarViewController.h"

@interface SidebarViewController ()

@end

@implementation SidebarViewController

@synthesize sidebarItems;

- (void)viewDidLoad {
  [super viewDidLoad];

  self.sidebarItems = [[SidebarDataSource sharedDataSource] items];

  self.outlineView.dataSource = self;
  self.outlineView.delegate = self;
  self.outlineView.style = NSTableViewStyleSourceList;
  self.outlineView.floatsGroupRows = NO;
  self.outlineView.headerView = nil;

  [self.outlineView expandItem:nil expandChildren:YES];
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (item == nil) {
    return self.sidebarItems.count;
  }

  SidebarItem *sidebarItem = (SidebarItem *)item;
  return sidebarItem.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (item == nil) {
    return self.sidebarItems[index];
  }

  return [(SidebarItem *)item children][index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return [(SidebarItem *)item children] != nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
  return [(SidebarItem *)item children] != nil;
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item {
  BOOL isGroupItem = [self outlineView:outlineView isGroupItem:item];

  SidebarItem *sidebarItem = (SidebarItem *)item;
  
  if (isGroupItem) {
    return [SidebarCellFactory headerCellForOutlineView:self.outlineView title:sidebarItem.title];
  } else {
    return [SidebarCellFactory itemCellForOutlineView:self.outlineView
                                                title:sidebarItem.title
                                           systemIcon:sidebarItem.iconName];
  }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
  SidebarItem *sidebarItem = (SidebarItem *)item;
  return sidebarItem.children != nil && ![sidebarItem.title isEqualToString:@"Library"];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
  NSInteger selectedRow = self.outlineView.selectedRow;
  SidebarItem *sidebarItem = (SidebarItem *)[self.outlineView itemAtRow:selectedRow];

  if (![self outlineView:self.outlineView isGroupItem:sidebarItem]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SidebarSelectionChanged"
                                                        object:sidebarItem];
  }
}

@end
