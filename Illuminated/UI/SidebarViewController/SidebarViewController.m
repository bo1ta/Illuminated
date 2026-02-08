//
//  SidebarViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 19.01.2026.
//

#import "SidebarViewController.h"
#import "Album.h"
#import "Carbon/Carbon.h"
#import "CoreDataStore.h"
#import "Playlist.h"
#import "PlaylistDataStore.h"
#import "SidebarCellFactory.h"
#import "SidebarItem.h"
#import "TrackDataStore.h"

#pragma mark - Constants

NSString *const SidebarSelectionItemDidChange = @"SidebarSelectionChanged";
NSString *const PasteboardItemTypeTrack = @"com.illuminated.track";

#pragma mark - Interface

@interface SidebarViewController ()<NSFetchedResultsControllerDelegate, NSTextFieldDelegate>

@property(nonatomic, strong) NSFetchedResultsController *playlistFetchedResultsController;
@property(nonatomic, strong) NSFetchedResultsController *albumFetchedResultsController;
@property(nonatomic, strong) NSArray<Playlist *> *playlists;
@property(nonatomic, strong) NSMutableArray<SidebarItem *> *sidebarItems;
@property(nonatomic, strong) id selectedRepresentedObject;

@end

#pragma mark - Implementation

@implementation SidebarViewController

@synthesize sidebarItems;

- (void)viewDidLoad {
  [super viewDidLoad];

  self.outlineView.dataSource = self;
  self.outlineView.delegate = self;
  self.outlineView.style = NSTableViewStyleSourceList;
  self.outlineView.floatsGroupRows = NO;
  self.outlineView.target = self;

  [self setupHeaderView];

  [self setupFetchedResultsControllers];
  [self buildSidebarItems];

  [self.outlineView reloadData];
  [self.outlineView expandItem:nil expandChildren:YES];
  [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];

  [self.outlineView registerForDraggedTypes:@[ PasteboardItemTypeTrack ]];
}

#pragma mark - UI setup

- (void)setupHeaderView {
  self.outlineView.headerView = nil;

  NSScrollView *scrollView = self.outlineView.enclosingScrollView;

  NSVisualEffectView *headerView = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0, 0, 200, 28)];
  headerView.translatesAutoresizingMaskIntoConstraints = NO;
  headerView.material = NSVisualEffectMaterialContentBackground;
  headerView.blendingMode = NSVisualEffectBlendingModeWithinWindow;
  headerView.state = NSVisualEffectStateFollowsWindowActiveState;

  NSTextField *titleLabel = [NSTextField labelWithString:@"PLAYLISTS"];
  titleLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightSemibold];
  titleLabel.textColor = [NSColor secondaryLabelColor];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

  NSButton *addButton = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"plus"
                                                            accessibilityDescription:@"Add Playlist"]
                                           target:self
                                           action:@selector(addPlaylistButtonClicked:)];
  addButton.bezelStyle = NSBezelStyleInline;
  addButton.bordered = NO;
  addButton.translatesAutoresizingMaskIntoConstraints = NO;

  [headerView addSubview:titleLabel];
  [headerView addSubview:addButton];

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
}

- (void)addPlaylistButtonClicked:(NSButton *)sender {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = @"New Playlist";
  alert.informativeText = @"Enter a name for your playlist:";
  [alert addButtonWithTitle:@"Create"];
  [alert addButtonWithTitle:@"Cancel"];

  NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 280, 24)];
  input.placeholderString = @"Playlist name";

  alert.accessoryView = input;
  alert.window.initialFirstResponder = input;

  [alert beginSheetModalForWindow:self.view.window
                completionHandler:^(NSModalResponse returnCode) {
                  if (returnCode == NSAlertFirstButtonReturn) {
                    NSString *playlistName = input.stringValue;
                    if (playlistName.length > 0) {
                      [PlaylistDataStore createPlaylistWithName:playlistName];
                    }
                  }
                }];
}

- (void)buildSidebarItems {
  NSMutableArray *items = [NSMutableArray array];

  /// All section
  SidebarItem *allMusicItem = [SidebarItem itemWithTitle:@"All Music" iconName:@"music.note"];
  allMusicItem.representedObject = [NSNull null];
  [items addObject:allMusicItem];

  /// Playlist Section
  NSArray<Playlist *> *playlists = [self.playlistFetchedResultsController fetchedObjects];
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

  // Albums section
  NSArray<Album *> *albums = [self.albumFetchedResultsController fetchedObjects];
  if (albums.count > 0) {
    NSMutableArray *albumItems = [NSMutableArray array];

    for (Album *album in albums) {
      SidebarItem *albumItem = [SidebarItem itemWithTitle:album.title iconName:@"square.stack"];
      albumItem.representedObject = album;
      [albumItems addObject:albumItem];
    }

    SidebarItem *albumsGroup = [SidebarItem groupWithTitle:@"Albums" children:albumItems];
    [items addObject:albumsGroup];
  }

  self.sidebarItems = items;
}

#pragma mark - NSFetchedResultsController

- (void)setupFetchedResultsControllers {
  NSSortDescriptor *playlistSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
  _playlistFetchedResultsController = [[CoreDataStore reader] fetchedResultsControllerForEntity:EntityNamePlaylist
                                                                                      predicate:nil
                                                                                sortDescriptors:@[ playlistSort ]];
  _playlistFetchedResultsController.delegate = self;

  NSError *error = nil;
  if (![self.playlistFetchedResultsController performFetch:&error]) {
    NSLog(@"SidebarViewController: Error performing Playlist fetch: %@", error.localizedDescription);
  }

  NSSortDescriptor *albumSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
  _albumFetchedResultsController = [[CoreDataStore reader] fetchedResultsControllerForEntity:EntityNameAlbum
                                                                                   predicate:nil
                                                                             sortDescriptors:@[ albumSort ]];
  _albumFetchedResultsController.delegate = self;

  if (![_albumFetchedResultsController performFetch:&error]) {
    NSLog(@"Error fetching albums: %@", error.localizedDescription);
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

#pragma mark - Drop Target

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView
                  validateDrop:(id<NSDraggingInfo>)info
                  proposedItem:(id)item
            proposedChildIndex:(NSInteger)index {
  if (item != nil && ![self outlineView:outlineView isGroupItem:item]) {
    SidebarItem *sidebarItem = (SidebarItem *)item;

    if ([sidebarItem.representedObject isKindOfClass:[Playlist class]]) {
      [outlineView setDropItem:item dropChildIndex:NSOutlineViewDropOnItemIndex];
      return NSDragOperationCopy;
    }
  }

  return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
         acceptDrop:(id<NSDraggingInfo>)info
               item:(id)item
         childIndex:(NSInteger)index {
  SidebarItem *sidebarItem = (SidebarItem *)item;
  Playlist *targetPlaylist = (Playlist *)sidebarItem.representedObject;

  NSPasteboard *pasteboard = [info draggingPasteboard];
  NSString *trackUUIDString = [pasteboard stringForType:PasteboardItemTypeTrack];

  if (trackUUIDString == nil) {
    return NO;
  }

  NSUUID *trackUUID = [[NSUUID alloc] initWithUUIDString:trackUUIDString];

  [PlaylistDataStore addToPlaylist:targetPlaylist trackWithUUID:trackUUID];

  return YES;
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
                                                      userInfo:@{@"playlist" : playlistValue}];
  }
}

#pragma mark - Editing on Return key

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  if ([self outlineView:outlineView isGroupItem:item]) {
    return NO;
  }

  SidebarItem *sidebarItem = (SidebarItem *)item;
  return [sidebarItem.representedObject isKindOfClass:[Playlist class]];
}

- (void)keyDown:(NSEvent *)event {
  if (event.keyCode != kVK_Return) {
    [super keyDown:event];
    return;
  }

  NSInteger row = self.outlineView.selectedRow;
  if (row == -1) {
    [super keyDown:event];
    return;
  }

  id item = [self.outlineView itemAtRow:row];
  if ([self outlineView:self.outlineView isGroupItem:item]) {
    [super keyDown:event];
    return;
  }

  SidebarItem *sidebarItem = (SidebarItem *)item;
  if (![sidebarItem.representedObject isKindOfClass:[Playlist class]]) {
    [super keyDown:event];
    return;
  }

  NSTableCellView *cell = [self.outlineView viewAtColumn:0 row:row makeIfNecessary:NO];
  if (cell && cell.textField) {
    cell.textField.editable = YES;
    cell.textField.selectable = YES;
    cell.textField.delegate = self;
  }

  [self.outlineView editColumn:0 row:row withEvent:event select:YES];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
  NSTextField *textField = obj.object;
  if (![textField isKindOfClass:[NSTextField class]]) {
    return;
  }

  NSInteger row = [self.outlineView rowForView:textField];
  if (row == -1) {
    return;
  }

  SidebarItem *item = [self.outlineView itemAtRow:row];
  if (!item || [item.representedObject isKindOfClass:[NSNull class]]) {
    return;
  }

  NSString *newName =
      [textField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (newName.length == 0 || [newName isEqualToString:item.title]) {
    textField.stringValue = item.title;
    return;
  }

  id represented = item.representedObject;
  if (![represented isKindOfClass:[Playlist class]]) {
    return;
  }

  Playlist *playlist = (Playlist *)represented;
  [PlaylistDataStore renamePlaylist:playlist toName:newName];

  item.title = newName;
  [self.outlineView reloadItem:item];
}

@end
