//
//  SidebarViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 19.01.2026.
//

#import "SidebarViewController.h"
#import "CoreDataStore.h"
#import "Playlist.h"
#import "SidebarHeaderView.h"

NSString *const SidebarSelectionItemDidChange = @"SidebarSelectionChanged";

@interface SidebarViewController () <NSFetchedResultsControllerDelegate>

@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong) NSArray<Playlist *> *playlists;
@property(nonatomic, strong) NSMutableArray<SidebarItem *> *sidebarItems;

@end

@implementation SidebarViewController

@synthesize sidebarItems;

- (void)viewDidLoad {
  [super viewDidLoad];

  self.outlineView.dataSource = self;
  self.outlineView.delegate = self;
  self.outlineView.style = NSTableViewStyleSourceList;
  self.outlineView.floatsGroupRows = NO;
  
  [self setupHeaderView];
  
  [self setupFetchedResultsController];
  [self buildSidebarItems];
  
  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
}

#pragma mark - UI setup

- (void)setupHeaderView {
  NSScrollView *scrollView = self.outlineView.enclosingScrollView;
    
    // Create header as a sibling to the scroll view
    NSView *headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 28)];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.wantsLayer = YES;
    headerView.layer.backgroundColor = [NSColor controlBackgroundColor].CGColor;
    
    NSTextField *titleLabel = [NSTextField labelWithString:@"PLAYLISTS"];
    titleLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
    titleLabel.textColor = [NSColor secondaryLabelColor];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSButton *addButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"plus" accessibilityDescription:@"Add Playlist"]
                                             target:self
                                             action:@selector(addPlaylistButtonClicked:)];
    addButton.bezelStyle = NSBezelStyleInline;
    addButton.bordered = NO;
    addButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [headerView addSubview:titleLabel];
    [headerView addSubview:addButton];
    
    // Add to parent view
    [self.view addSubview:headerView];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
      [headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
      [headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [headerView.heightAnchor constraintEqualToConstant:28],
      
      [scrollView.topAnchor constraintEqualToAnchor:headerView.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

      
      [titleLabel.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:8],
      [titleLabel.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
      
      [addButton.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor constant:-8],
      [addButton.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor]
    ]];
    
    // Keep outline view header nil
    self.outlineView.headerView = nil;
}

- (void)addPlaylistButtonClicked:(NSButton *)sender {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = @"New Playlist";
  alert.informativeText = @"Enter a name for your playlist:";
  [alert addButtonWithTitle:@"Create"];
  [alert addButtonWithTitle:@"Cancel"];
  
  // Create text field
  NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 280, 24)];
  input.placeholderString = @"Playlist name";
  
  alert.accessoryView = input;
  alert.window.initialFirstResponder = input;
  
  [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSAlertFirstButtonReturn) {
      NSString *playlistName = input.stringValue;
      if (playlistName.length > 0) {
        [[CoreDataStore writer] createPlaylistWithName:playlistName];
      } else {
        NSLog(@"Empty playlist name");
      }
    } else {
      NSLog(@"Cancelled");
    }
  }];
}

- (void)buildSidebarItems {
  NSMutableArray *items = [NSMutableArray array];
  
  SidebarItem *allMusicItem = [SidebarItem itemWithTitle:@"All Music" iconName:@"music.note"];
  allMusicItem.representedObject = [NSNull null];
  [items addObject:allMusicItem];
  
  NSArray<Playlist *> *playlists = [self.fetchedResultsController fetchedObjects];
  if (playlists.count > 0) {
    NSMutableArray *playlistItems = [NSMutableArray array];
    
    for (Playlist *playlist in playlists) {
      NSString *iconName = playlist.iconName ?: @"music.note.list";
      SidebarItem *playlistItem = [SidebarItem itemWithTitle:playlist.name iconName:iconName];
      playlistItem.representedObject = playlist;
      [playlistItems addObject:playlistItem];
    }
    
    SidebarItem *playlistsGroup = [SidebarItem groupWithTitle:@"Playlists" children:playlistItems];
    [items addObject:playlistsGroup];
  }
  
  self.sidebarItems = items;
}

#pragma mark - NSFetchedResultsController

- (void)setupFetchedResultsController {
  _fetchedResultsController = [[CoreDataStore reader] fetchedResultsControllerForEntity:EntityNamePlaylist
                                                                              predicate:nil
                                                                        sortDescriptors:nil];
  _fetchedResultsController.delegate = self;

  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
    NSLog(@"SidebarViewController: Error performing Playlist fetch: %@", error.localizedDescription);
  } else {
    self.playlists = (NSArray<Playlist *> *)[self.fetchedResultsController fetchedObjects];
  }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self buildSidebarItems];
  [self.outlineView reloadData];
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

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
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
    id playlistValue = sidebarItem.representedObject ?: [NSNull null];
    [[NSNotificationCenter defaultCenter] postNotificationName:SidebarSelectionItemDidChange
                                                           object:nil
                                                      userInfo:@{@"playlist": playlistValue}];
  }
}

@end
