//
//  MusicViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "MusicViewController.h"
#import "Album.h"
#import "Artist.h"
#import "CoreDataStore.h"
#import "MainWindowController.h"
#import "PlaybackManager.h"
#import "Playlist.h"
#import "SidebarViewController.h"
#import "TrackDataStore.h"
#import "BFExecutor.h"
#import "Track.h"
#import "TrackImportService.h"

#pragma mark - Constants

typedef NSString *MusicColumn;
static MusicColumn const MusicColumnNumber = @"NumberColumn";
static MusicColumn const MusicColumnSong = @"SongColumn";
static MusicColumn const MusicColumnArtist = @"ArtistColumn";
static MusicColumn const MusicColumnBPM = @"BPMColumn";
static MusicColumn const MusicColumnTime = @"TimeColumn";

#pragma mark - Private Interface

@interface MusicViewController ()

@property(atomic, strong) NSArray<Track *> *tracks;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong, nullable) Playlist *currentPlaylist;
@property(nonatomic, strong, nullable) Album *currentAlbum;

@end

#pragma mark - Implementation

@implementation MusicViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];

  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.doubleAction = @selector(tableViewClicked:);

  [self.tableView registerForDraggedTypes:@[ NSPasteboardTypeFileURL ]];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
  self.tableView.draggingDestinationFeedbackStyle = NSTableViewDraggingDestinationFeedbackStyleRegular;

  [self setupFetchedResultsController];
  [self setupNotifications];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupFetchedResultsController {
  _fetchedResultsController = [[CoreDataStore reader] fetchedResultsControllerForEntity:EntityNameTrack
                                                                              predicate:nil
                                                                        sortDescriptors:nil];
  _fetchedResultsController.delegate = self;

  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
    NSLog(@"MusicViewController: Error loading tracks for fetched results: %@", error.localizedDescription);
  } else {
    self.tracks = (NSArray<Track *> *)[self.fetchedResultsController fetchedObjects];
  }
}

#pragma mark - Notifications

- (void)setupNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(selectCurrentTrack)
                                               name:PlaybackManagerTrackDidChangeNotification
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sidebarSelectionDidChange:)
                                               name:SidebarSelectionItemDidChange
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(toolbarSearchDidChange:)
                                               name:ToolbarSearchDidChangeNotification
                                             object:nil];
}

- (void)toolbarSearchDidChange:(NSNotification *)notification {
  NSString *searchText = notification.userInfo[ToolbarSearchUserInfo];
  NSMutableArray *predicates = [NSMutableArray array];

  if (searchText.length > 0) {
    NSPredicate *searchPredicate = [NSPredicate
        predicateWithFormat:@"title CONTAINS[cd] %@ OR artist.name CONTAINS[cd] %@ OR album.title CONTAINS[cd] %@",
                            searchText,
                            searchText,
                            searchText];
    [predicates addObject:searchPredicate];
  } else {
    [self updateFetchedResultsControllerForCurrentPlaylist];
    return;
  }

  if (self.currentPlaylist != nil) {
    [predicates addObject:[NSPredicate predicateWithFormat:@"ANY playlists == %@", self.currentPlaylist]];
  } else if (self.currentAlbum != nil) {
    [predicates addObject:[NSPredicate predicateWithFormat:@"album == %@", self.currentAlbum]];
  }

  NSPredicate *finalPredicate = nil;
  if (predicates.count > 0) {
    finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
  }

  self.fetchedResultsController.fetchRequest.predicate = finalPredicate;
  [self.fetchedResultsController performFetch:nil];

  self.tracks = (NSArray<Track *> *)[self.fetchedResultsController fetchedObjects];
  [self.tableView reloadData];
  [self selectRowForTrack:[[PlaybackManager sharedManager] currentTrack] scroll:NO];
}

- (void)selectCurrentTrack {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
    [self selectRowForTrack:[[PlaybackManager sharedManager] currentTrack] scroll:YES];
  });

  Track *playingTrack = [[PlaybackManager sharedManager] currentTrack];
  [TrackDataStore incrementPlayCountForTrack:playingTrack];

  if (playingTrack.bpm <= 0) {
    NSURL *currentURL = [[PlaybackManager sharedManager] currentPlaybackURL];
    [[BFTask taskFromExecutor:[BFExecutor defaultExecutor]
                    withBlock:^id { return [TrackImportService analyzeBPMForTrackURL:currentURL]; }]
        continueOnMainThreadWithBlock:^id(BFTask<Track *> *task) {
          if (!task.error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerTrackDidChangeNotification
                                                                object:nil];
          }
          return task;
        }];
  }
}

- (void)sidebarSelectionDidChange:(NSNotification *)notification {
  id playlistObject = notification.userInfo[@"playlist"];

  if ([playlistObject isKindOfClass:[Playlist class]]) {
    self.currentPlaylist = (Playlist *)playlistObject;
    self.currentAlbum = nil;
  } else if ([playlistObject isKindOfClass:[Album class]]) {
    self.currentAlbum = (Album *)playlistObject;
    self.currentPlaylist = nil;
  } else {
    self.currentAlbum = nil;
    self.currentPlaylist = nil;
  }

  [self updateFetchedResultsControllerForCurrentPlaylist];
}

#pragma mark - Drag & Drop methods

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
  Track *track = self.tracks[row];

  NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
  [item setString:track.uniqueID.UUIDString forType:PasteboardItemTypeTrack];

  return item;
}

- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)dropOperation {
  NSPasteboard *pasteboard = [info draggingPasteboard];
  NSArray<NSURL *> *fileURLs = [pasteboard readObjectsForClasses:@[ [NSURL class] ] options:@{}];

  if (fileURLs.count == 0) return NO;

  NSMutableArray<NSURL *> *resolvedURLs = [NSMutableArray array];
  NSSet *audioExtensions = [NSSet setWithArray:@[ @"mp3", @"m4a", @"wav", @"aiff", @"flac", @"aac", @"ogg", @"wma" ]];

  for (NSURL *url in fileURLs) {
    NSURL *standardURL = [url filePathURL];

    NSString *extension = [[standardURL pathExtension] lowercaseString];
    if ([audioExtensions containsObject:extension]) {
      [resolvedURLs addObject:standardURL];
    }
  }

  if (resolvedURLs.count == 0) {
    return NO;
  } else if (resolvedURLs.count == 1) {
    [self importURL:resolvedURLs.firstObject];
  } else {
    [self importURLs:resolvedURLs];
  }

  return YES;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  self.tracks = (NSArray<Track *> *)[controller fetchedObjects];
  [self.tableView reloadData];
  [self selectRowForTrack:[[PlaybackManager sharedManager] currentTrack] scroll:NO];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return self.tracks.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSString *columnIdentifier = tableColumn.identifier;

  NSTableCellView *cell = [tableView makeViewWithIdentifier:columnIdentifier owner:self];
  if (cell == nil) {
    cell = [[NSTableCellView alloc] init];
    cell.identifier = columnIdentifier;

    NSTextField *textField = [[NSTextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.bordered = NO;
    textField.drawsBackground = NO;
    textField.editable = NO;
    cell.textField = textField;
    [cell addSubview:textField];

    [NSLayoutConstraint activateConstraints:@[
      [textField.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:8],
      [textField.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-8],
      [textField.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor]
    ]];
  }

  Track *track = self.tracks[row];
  Track *playingTrack = [[PlaybackManager sharedManager] currentTrack];
  BOOL isPlaying = track && playingTrack && [track.objectID isEqual:playingTrack.objectID];

  if ([columnIdentifier isEqualToString:MusicColumnNumber]) {
    cell.textField.alignment = NSTextAlignmentCenter;
    cell.textField.stringValue = [NSString stringWithFormat:@"%ld", (long)row + 1];
  } else if ([columnIdentifier isEqualToString:MusicColumnSong]) {
    cell.textField.stringValue = track.title;
    cell.textField.alignment = NSTextAlignmentLeft;
  } else if ([columnIdentifier isEqualToString:MusicColumnArtist]) {
    cell.textField.stringValue = track.artist.name ?: @"Unknown";
    cell.textField.alignment = NSTextAlignmentLeft;
  } else if ([columnIdentifier isEqualToString:MusicColumnBPM]) {
    cell.textField.stringValue = track.roundedBPM ? [NSString stringWithFormat:@"%@", track.roundedBPM] : @"-";
    cell.textField.alignment = NSTextAlignmentCenter;
  } else if ([columnIdentifier isEqualToString:MusicColumnTime]) {
    cell.textField.stringValue = [self formatTime:track.duration];
    cell.textField.alignment = NSTextAlignmentLeft;
  }

  cell.textField.font = isPlaying ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:13];

  return cell;
}

- (NSString *)formatTime:(NSTimeInterval)seconds {
  NSInteger mins = (NSInteger)seconds / 60;
  NSInteger secs = (NSInteger)seconds % 60;
  return [NSString stringWithFormat:@"%ld:%02ld", mins, secs];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  return 24.0;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
  NSString *columnIdentifier = tableColumn.identifier;
  NSMutableArray<NSSortDescriptor *> *sortDescriptors = [NSMutableArray array];

  NSArray<NSSortDescriptor *> *existingDescriptors = [self.fetchedResultsController.fetchRequest.sortDescriptors copy];

  if ([columnIdentifier isEqualToString:MusicColumnSong]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                ascending:![self isSortDescriptorForKey:@"title"
                                                                       ascendingInArray:existingDescriptors]]];
  } else if ([columnIdentifier isEqualToString:MusicColumnArtist]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"artist.name"
                                                ascending:![self isSortDescriptorForKey:@"artist.name"
                                                                       ascendingInArray:existingDescriptors]]];
  } else if ([columnIdentifier isEqualToString:MusicColumnBPM]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"bpm"
                                                ascending:![self isSortDescriptorForKey:@"bpm"
                                                                       ascendingInArray:existingDescriptors]]];
  } else if ([columnIdentifier isEqualToString:MusicColumnTime]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"duration"
                                                ascending:![self isSortDescriptorForKey:@"duration"
                                                                       ascendingInArray:existingDescriptors]]];
  } else if ([columnIdentifier isEqualToString:MusicColumnNumber]) {
    // do nothing here and let the empty array propagate to sort descriptors for reset
  } else {
    return;
  }

  self.fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors;

  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
    NSLog(@"Error performing fetch request. Error: %@", error);
    return;
  }
  
  [self reloadData];
}

- (BOOL)isSortDescriptorForKey:(NSString *)key ascendingInArray:(NSArray<NSSortDescriptor *> *)descriptors {
  for (NSSortDescriptor *descriptor in descriptors) {
    if ([descriptor.key isEqualToString:key]) {
      return descriptor.ascending;
    }
  }
  return NO;
}

- (void)reloadData {
  self.tracks = (NSArray<Track *> *)[self.fetchedResultsController fetchedObjects];
  [self.tableView reloadData];

  [self selectRowForTrack:[[PlaybackManager sharedManager] currentTrack] scroll:NO];
}

#pragma mark - Private Helpers

- (void)selectRowForTrack:(Track *)track scroll:(BOOL)scroll {
  if (track == nil) {
    [self.tableView deselectAll:nil];
    return;
  }

  NSUInteger rowIndex = [self.tracks indexOfObjectPassingTest:^BOOL(Track *obj, NSUInteger _, BOOL *stop) {
    BOOL matches = [obj.objectID isEqual:track.objectID];
    if (matches) {
      *stop = YES;
    }
    return matches;
  }];

  if (rowIndex == NSNotFound) {
    [self.tableView deselectAll:nil];
    return;
  }

  NSIndexSet *row = [NSIndexSet indexSetWithIndex:rowIndex];
  [self.tableView selectRowIndexes:row byExtendingSelection:NO];

  if (scroll) {
    [self.tableView scrollRowToVisible:(NSInteger)rowIndex];
  }
}

- (void)updateFetchedResultsControllerForCurrentPlaylist {
  NSPredicate *predicate = nil;
  if (self.currentPlaylist != nil) {
    predicate = [NSPredicate predicateWithFormat:@"ANY playlists == %@", self.currentPlaylist];
  } else if (self.currentAlbum != nil) {
    predicate = [NSPredicate predicateWithFormat:@"album == %@", self.currentAlbum];
  }

  self.fetchedResultsController.fetchRequest.predicate = predicate;
  [self.fetchedResultsController performFetch:nil];

  [self reloadData];
}

- (void)tableViewClicked:(id)sender {
  if (self.tableView.selectedRow >= 0) {
    Track *selectedTrack = self.tracks[self.tableView.selectedRow];

    [[PlaybackManager sharedManager] updateQueue:self.tracks];
    [[PlaybackManager sharedManager] playTrack:selectedTrack];
  }
}

- (void)importURLs:(NSArray<NSURL *> *)urls {
  [TrackDataStore importTracksFromAudioURLs:urls playlist:self.currentPlaylist];
}

- (void)importURL:(NSURL *)url {
  [[TrackDataStore findOrInsertByURL:url
                            playlist:self.currentPlaylist]
   continueWithSuccessBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      [[PlaybackManager sharedManager] playTrack:track];
    }
    return nil;
  }];
}

@end
