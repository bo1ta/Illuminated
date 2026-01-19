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
    
    self.sidebarItems = [self buildSidebarItems];
    
    self.outlineView.dataSource = self;
    self.outlineView.delegate = self;
    
    self.outlineView.style = NSTableViewStyleSourceList;
    self.outlineView.floatsGroupRows = NO;
    
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (NSArray *)buildSidebarItems {
    return @[
        @{
            @"title": @"Library",
            @"children": @[
                @{@"title": @"Music", @"icon": @"music.note"},
                @{@"title": @"Movies", @"icon": @"film"}
            ]
        },
        @{
            @"title": @"Playlists",
            @"children": @[
                @{@"title": @"My Top Played", @"icon": @"star.fill"},
                @{@"title": @"Recently Added", @"icon": @"clock"},
                @{@"title": @"Chill Vibes", @"icon": @"music.note.list"},
                @{@"title": @"Classic Rock", @"icon": @"guitars"}
            ]
        }
    ];
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return self.sidebarItems.count;
    }
    
    NSArray *children = item[@"children"];
    return children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return self.sidebarItems[index];
    }
    
    return item[@"children"][index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return item[@"children"] != nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return item[@"children"] != nil;
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    BOOL isGroupItem = [self outlineView:outlineView isGroupItem:item];
    
    if (isGroupItem) {
        NSTableCellView *cell = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        if (!cell) {
            cell = [[NSTableCellView alloc] init];
            cell.identifier = @"HeaderCell";
            
            NSTextField *textField = [[NSTextField alloc] init];
            textField.bordered = NO;
            textField.backgroundColor = [NSColor clearColor];
            textField.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
            textField.textColor = [NSColor secondaryLabelColor];
            cell.textField = textField;
            [cell addSubview:textField];
        }
        
        cell.textField.stringValue = [item[@"title"] uppercaseString];
        return cell;
    } else {
        NSTableCellView *cell = [outlineView makeViewWithIdentifier:@"ItemCell" owner:self];
        if (!cell) {
            cell = [[NSTableCellView alloc] init];
            cell.identifier = @"ItemCell";
            
            NSImageView *imageView = [[NSImageView alloc] init];
            cell.imageView = imageView;
            [cell addSubview:imageView];
            
            NSTextField *textField = [[NSTextField alloc] init];
            textField.bordered = NO;
            textField.backgroundColor = [NSColor clearColor];
            cell.textField = textField;
            [cell addSubview:textField];
        }
        
        cell.textField.stringValue = item[@"title"];
        cell.imageView.image = [NSImage imageNamed:item[@"icon"]];
        return cell;
    }
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = self.outlineView.selectedRow;
    id item = [self.outlineView itemAtRow:selectedRow];
    
    if (![self outlineView:self.outlineView isGroupItem:item]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SidebarSelectionChanged" object:item];
    }
}

@end
