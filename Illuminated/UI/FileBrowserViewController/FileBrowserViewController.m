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
#import "CoreDataStore.h"
#import "FileBrowserItem.h"
#import "FileBrowserService.h"
#import "PlaybackManager.h"
#import "Track.h"
#import "TrackDataStore.h"

@interface FileBrowserViewController ()

@property(nonatomic, strong) FileBrowserService *browserService;
@property(nonatomic, strong) NSArray<FileBrowserItem *> *items;
@property(nonatomic, strong) NSURL *currentDirectoryURL;
@property(weak) IBOutlet NSOutlineView *outlineView;
@property(nonatomic, strong) NSData *currentBookmarkData;

@end

@implementation FileBrowserViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.outlineView.dataSource = self;
  self.outlineView.delegate = self;
  self.outlineView.target = self;
  self.outlineView.doubleAction = @selector(outlineViewDoubleClicked:);
  self.outlineView.rowHeight = 24.0;
}

- (void)viewDidAppear {
  [super viewDidAppear];

  [self loadMusicFolder];
}

#pragma mark - Data Loading

- (void)loadMusicFolder {
  NSData *bookmarkData = [BookmarkResolver bookmarkForMusicFolder];
  if (bookmarkData) {
    NSError *error = nil;
    NSURL *url = [BookmarkResolver resolveAndAccessBookmarkData:bookmarkData error:&error];
    if (error) {
      NSLog(@"Error resolving music folder: %@", error);
    } else {
      self.currentDirectoryURL = url;
      self.currentBookmarkData = bookmarkData;

      [self reloadFromBookmarkedFolder];
    }
  } else {
    [self chooseMusicFolder];
  }
}

- (void)chooseMusicFolder {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.allowsMultipleSelection = NO;
  panel.message = @"Select your music folder";
  panel.prompt = @"Select";

  NSWindow *window = self.view.window;
  if (!window) return; // safety

  [panel beginSheetModalForWindow:window
                completionHandler:^(NSModalResponse returnCode) {
                  if (returnCode == NSModalResponseOK) {
                    NSURL *selectedURL = panel.URLs.firstObject;
                    if (selectedURL) {
                      NSError *error = nil;
                      NSData *bookmarkData = [BookmarkResolver storeMusicFolderBookmarkForURL:selectedURL error:&error];
                      if (bookmarkData) {
                        self.currentBookmarkData = bookmarkData;
                        [self reloadFromBookmarkedFolder];
                      } else {
                        [self presentError:error];
                      }
                    }
                  }
                }];
}

- (void)reloadFromBookmarkedFolder {
  NSURL *scopedURL = [BookmarkResolver resolveMusicFolder];
  if (!scopedURL) {
    return;
  }

  [self reloadDirectory:scopedURL];
}

- (void)reloadDirectory:(NSURL *)directoryURL {
  BOOL hasScope = [directoryURL startAccessingSecurityScopedResource];

  [[self.browserService contentsOfDirectory:directoryURL]
      continueOnMainThreadWithBlock:^id(BFTask<NSArray<FileBrowserItem *> *> *task) {
        if (task.error) {
          [self presentError:task.error];
          if (hasScope) {
            [directoryURL stopAccessingSecurityScopedResource];
          }
          return nil;
        }

        self.currentDirectoryURL = directoryURL;

        NSMutableArray<FileBrowserItem *> *items = [NSMutableArray array];
        NSURL *parentURL = [directoryURL URLByDeletingLastPathComponent];
        if (parentURL && ![parentURL isEqual:directoryURL]) {
          NSImage *folderIcon = [NSImage imageNamed:NSImageNameFolder];
          FileBrowserItem *parentItem = [[FileBrowserItem alloc] initWithURL:parentURL
                                                                 displayName:@".."
                                                                   directory:YES
                                                              typeIdentifier:nil
                                                                        icon:folderIcon];
          [items addObject:parentItem];
        }

        if (task.result.count > 0) {
          [items addObjectsFromArray:task.result];
        }

        self.items = items;
        [self.outlineView reloadData];
        [self.outlineView expandItem:nil expandChildren:YES];
        if (hasScope) {
          [directoryURL stopAccessingSecurityScopedResource];
        }
        return nil;
      }];
}

#pragma mark - Actions

- (void)outlineViewDoubleClicked:(id)sender {
  NSInteger row = self.outlineView.clickedRow;
  if (row == -1) {
    row = self.outlineView.selectedRow;
  }
  if (row < 0 || row >= self.items.count) return;

  FileBrowserItem *item = [self.outlineView itemAtRow:row];
  if (item.isDirectory) {
    [self reloadDirectory:item.url];
  } else {
    [self previewTrackForURL:item.url];
  }
}

- (void)previewTrackForURL:(NSURL *)url {
  NSURL *scopedURL = [self.currentDirectoryURL URLByAppendingPathComponent:url.lastPathComponent];
  [[TrackDataStore findOrInsertByURL:scopedURL
                        bookmarkData:self.currentBookmarkData] continueWithSuccessBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    [[PlaybackManager sharedManager] playTrack:track];
    return nil;
  }];
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (item == nil) {
    return self.items.count;
  }
  return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  if (item == nil) {
    return self.items[index];
  }
  return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return NO;
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
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

#pragma mark - Lazy properties

- (FileBrowserService *)browserService {
  if (_browserService == nil) {
    _browserService = [[FileBrowserService alloc] init];
  }
  return _browserService;
}

- (NSURL *)userHomeDirectoryURL {
  return [NSFileManager defaultManager].homeDirectoryForCurrentUser;
}

@end
