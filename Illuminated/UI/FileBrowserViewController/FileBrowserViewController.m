//
//  FileBrowserViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import "FileBrowserViewController.h"
#import "AppDelegate.h"
#import "BFTask.h"
#import "BookmarkResolver.h"
#import "FileBrowserItem.h"
#import "FileBrowserService.h"
#import "PlaybackManager.h"
#import "Track.h"
#import "TrackService.h"

NSString *const PasteboardItemTypeTrackImport = @"com.illuminated.track.import";

@interface FileBrowserViewController ()

@property(nonatomic, strong) FileBrowserService *browserService;
@property(nonatomic, strong) NSArray<FileBrowserItem *> *rootItems;
@property(nonatomic, strong) NSMutableDictionary<NSValue *, NSArray<FileBrowserItem *> *> *loadedItems;
@property(weak) IBOutlet NSOutlineView *outlineView;

@end

@implementation FileBrowserViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.loadedItems = [NSMutableDictionary dictionary];
  
  self.outlineView.dataSource = self;
  self.outlineView.delegate = self;
  self.outlineView.target = self;
  self.outlineView.doubleAction = @selector(outlineViewDoubleClicked:);
  self.outlineView.rowHeight = 24.0;
  
  [self.outlineView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  
  [self loadRootLocations];
}

#pragma mark - Data Loading

- (void)addLocationURL:(NSURL *)url {
  [[self.browserService createFileBrowserItemWithURL:url]
   continueOnMainThreadWithBlock:^id(BFTask<FileBrowserItem *> *task) {
    if (task.error) {
      [self presentError:task.error];
      return nil;
    }
    
    [self loadRootLocations];
    return nil;
  }];
}

- (void)loadRootLocations {
  [[self.browserService allFileBrowserItems]
   continueOnMainThreadWithBlock:^id(BFTask<NSArray<FileBrowserItem *> *> *task) {
    if (task.error) {
      [self presentError:task.error];
      return nil;
    }
    
    self.rootItems = task.result;
    [self.outlineView reloadData];
    return nil;
  }];
}

- (void)reloadDirectory:(NSURL *)directoryURL bookmarkData:(NSData *)bookmarkData forItem:(FileBrowserItem *)item {
  NSURL *securityScopedURL = nil;
  if (bookmarkData) {
    NSError *error = nil;
    securityScopedURL = [BookmarkResolver resolveAndAccessBookmarkData:bookmarkData error:&error];
    if (error) {
      NSLog(@"Error resolving bookmark: %@", error);
    }
  }
  
  BOOL hasScope = [securityScopedURL startAccessingSecurityScopedResource];
  
  __weak typeof(self) weakSelf = self;
  
  [[self.browserService contentsOfDirectory:directoryURL bookmarkData:bookmarkData]
   continueOnMainThreadWithBlock:^id(BFTask<NSArray<FileBrowserItem *> *> *task) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    
    if (task.error) {
      [strongSelf presentError:task.error];
      if (hasScope) {
        [securityScopedURL stopAccessingSecurityScopedResource];
      }
      return nil;
    }
    
    strongSelf.loadedItems[[NSValue valueWithNonretainedObject:item]] = task.result;
    [strongSelf.outlineView reloadItem:item reloadChildren:YES];
    [strongSelf.outlineView expandItem:item];
    
    if (hasScope) {
      [securityScopedURL stopAccessingSecurityScopedResource];
    }
    return nil;
  }];
}

#pragma mark - Actions

- (IBAction)addFolderAction:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.allowsMultipleSelection = NO;
  panel.message = @"Select a music folder to add";
  panel.prompt = @"Add";
  
  NSWindow *window = self.view.window;
  if (!window) return;
  
  [panel beginSheetModalForWindow:window
                completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSModalResponseOK) {
      NSURL *selectedURL = panel.URLs.firstObject;
      if (selectedURL) {
        [self addLocationURL:selectedURL];
      }
    }
  }];
}

- (void)outlineViewDoubleClicked:(id)sender {
  NSInteger row = self.outlineView.clickedRow;
  if (row == -1) {
    row = self.outlineView.selectedRow;
  }
  if (row < 0) return;
  
  FileBrowserItem *item = [self.outlineView itemAtRow:row];
  if (item.isDirectory) {
    if ([self.outlineView isItemExpanded:item]) {
      [self.outlineView collapseItem:item];
    } else {
      [self reloadDirectory:item.url bookmarkData:item.bookmarkData forItem:item];
    }
  } else {
    [self previewTrackForItem:item];
  }
}

- (void)previewTrackForItem:(FileBrowserItem *)item {
  [[TrackService findOrInsertByURL:item.url
                      bookmarkData:item.bookmarkData] continueOnMainThreadWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    [[PlaybackManager sharedManager] playTrack:track];
    return nil;
  }];
}

#pragma mark - NSOutlineViewDataSource

- (id<NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView
               pasteboardWriterForItem:(id)item {
  FileBrowserItem *browserItem = (FileBrowserItem *)item;
  
  NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
  [pasteboardItem setString:browserItem.url.absoluteString forType:PasteboardItemTypeTrackImport];
  return pasteboardItem;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (item == nil) {
    return self.rootItems.count;
  }
  
  NSValue *key = [NSValue valueWithNonretainedObject:item];
  return self.loadedItems[key].count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (item == nil) {
    return self.rootItems[index];
  }
  
  NSValue *key = [NSValue valueWithNonretainedObject:item];
  return self.loadedItems[key][index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  FileBrowserItem *browserItem = (FileBrowserItem *)item;
  return browserItem.isDirectory;
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView
     viewForTableColumn:(NSTableColumn *)tableColumn
                   item:(id)item {
  FileBrowserItem *browserItem = (FileBrowserItem *)item;
  
  NSTableCellView *cellView = [outlineView makeViewWithIdentifier:@"FileCell" owner:self];
  if (cellView == nil) {
    cellView = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, self.outlineView.rowHeight)];
    cellView.identifier = @"FileCell";
    
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.imageScaling = NSImageScaleProportionallyDown;
    cellView.imageView = imageView;
    [cellView addSubview:imageView];
    
    NSTextField *textField = [NSTextField labelWithString:@""];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.lineBreakMode = NSLineBreakByTruncatingMiddle;
    cellView.textField = textField;
    [cellView addSubview:textField];
    
    [NSLayoutConstraint activateConstraints:@[
      [imageView.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor constant:6],
      [imageView.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor],
      [imageView.widthAnchor constraintEqualToConstant:16],
      [imageView.heightAnchor constraintEqualToConstant:16],
      
      [textField.leadingAnchor constraintEqualToAnchor:imageView.trailingAnchor constant:6],
      [textField.trailingAnchor constraintEqualToAnchor:cellView.trailingAnchor constant:-6],
      [textField.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor]
    ]];
  }
  
  cellView.textField.stringValue = browserItem.displayName;
  cellView.imageView.image = browserItem.icon;
  
  return cellView;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
  return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
  FileBrowserItem *browserItem = (FileBrowserItem *)item;
  NSValue *key = [NSValue valueWithNonretainedObject:browserItem];
  
  if (self.loadedItems[key] == nil) {
    [self reloadDirectory:browserItem.url bookmarkData:browserItem.bookmarkData forItem:browserItem];
    return NO;
  }
  
  return YES;
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
  FileBrowserItem *item = notification.userInfo[@"NSObject"];
  [self unloadItemsForItem:item];
}

#pragma mark - Private Helpers

- (void)unloadItemsForItem:(FileBrowserItem *)item {
  NSValue *key = [NSValue valueWithNonretainedObject:item];
  NSArray<FileBrowserItem *> *children = self.loadedItems[key];
  
  if (children) {
    for (FileBrowserItem *child in children) {
      [self unloadItemsForItem:child];
    }
    [self.loadedItems removeObjectForKey:key];
  }
}

- (FileBrowserService *)browserService {
  if (_browserService == nil) {
    _browserService = [[FileBrowserService alloc] init];
  }
  return _browserService;
}

@end
