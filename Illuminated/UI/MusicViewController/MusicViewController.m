//
//  MusicViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "MusicViewController.h"
#import "Album.h"
#import "Artist.h"
#import "BFExecutor.h"
#import "FileBrowserViewController.h"
#import "MainWindowController.h"
#import "PlaybackManager.h"
#import "Playlist.h"
#import "PlaylistDataStore.h"
#import "RadioBrowserClient.h"
#import "SidebarViewController.h"
#import "Track.h"
#import "TrackDataStore.h"
#import "TrackService.h"

#pragma mark - Constants

typedef NSString *MusicColumn;
static MusicColumn const MusicColumnNumber = @"NumberColumn";
static MusicColumn const MusicColumnSong = @"SongColumn";
static MusicColumn const MusicColumnArtist = @"ArtistColumn";
static MusicColumn const MusicColumnBPM = @"BPMColumn";
static MusicColumn const MusicColumnTime = @"TimeColumn";

NSString *const PasteboardItemTypeTrackImports = @"com.illuminated.track.import";

#pragma mark - Private Interface

@interface MusicViewController ()

@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong, nullable) Playlist *currentPlaylist;
@property(nonatomic, strong, nullable) Album *currentAlbum;
@property(nonatomic, strong, nullable) Track *currentTrack;

@property(nonatomic, strong) RadioBrowserClient *radioClient;

@end

#pragma mark - Implementation

@implementation MusicViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _radioClient = [[RadioBrowserClient alloc] init];
  
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.doubleAction = @selector(tableViewClicked:);
  
  [self.tableView registerForDraggedTypes:@[ NSPasteboardTypeFileURL, PasteboardItemTypeTrackImport ]];
  [self.tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
  self.tableView.draggingDestinationFeedbackStyle = NSTableViewDraggingDestinationFeedbackStyleRegular;
  
  self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  self.view.translatesAutoresizingMaskIntoConstraints = YES;
  
  [self setupFetchedResultsController];
  [self setupNotifications];
}

- (void)loadRadioStations {
  [[self.radioClient listAllStations] continueWithBlock:^id(BFTask<NSArray<RBStation *> *> *task) {
    if (task.error) {
      NSLog(@"Error loading radio stations: %@", task.error);
    } else {
      NSLog(@"Loaded radio stations: %@", task.result);
    }
    return nil;
  }];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupFetchedResultsController {
  _fetchedResultsController = [TrackDataStore fetchedResultsController];
  _fetchedResultsController.delegate = self;
  
  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
    NSLog(@"MusicViewController: Error loading tracks for fetched results: %@", error.localizedDescription);
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
  
  [self.tableView reloadData];
}

- (void)selectCurrentTrack {
  _currentTrack = [[PlaybackManager sharedManager] currentTrack];
  
  if (!self.currentTrack) {
    return;
  }
  
  [self selectRowForTrack:self.currentTrack scroll:YES];
  
  [TrackDataStore incrementPlayCountForTrack:self.currentTrack];
  
  if (self.currentTrack.bpm <= 0) {
    NSURL *currentURL = [[PlaybackManager sharedManager] currentPlaybackURL];
    [BFTask taskFromExecutor:[BFExecutor defaultExecutor]
                   withBlock:^id { return [TrackService analyzeBPMForTrackURL:currentURL]; }];
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
  Track *track = self.fetchedResultsController.fetchedObjects[row];
  
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
    NSMutableArray<NSURL *> *fileURLs = [[pasteboard readObjectsForClasses:@[ [NSURL class] ] options:@{}] mutableCopy];
    
    if (fileURLs.count == 0) {
        NSString *absoluteURL = [pasteboard stringForType:PasteboardItemTypeTrackImport];
        
        NSURL *url = [NSURL URLWithString:absoluteURL];
        if (url) {
            fileURLs = [NSMutableArray arrayWithObject:url];
        } else {
            return NO;
        }
    }
    
    NSSet *audioExtensions = [NSSet setWithArray:@[@"mp3", @"m4a", @"wav", @"aiff",
                                                   @"flac", @"aac", @"ogg", @"wma"]];
    
    NSMutableArray<NSURL *> *resolvedURLs = [NSMutableArray array];
    
    for (NSURL *url in fileURLs) {
        NSURL *standardURL = [url filePathURL];
        NSString *extension = [standardURL.pathExtension lowercaseString];
        
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

-(void)controllerDidChangeContent : (NSFetchedResultsController *)controller {
  [self.tableView reloadData];
  [self selectRowForTrack:self.currentTrack scroll:NO];
}

#pragma mark - NSTableViewDataSource

-(NSInteger)numberOfRowsInTableView : (NSTableView *)tableView {
  return self.fetchedResultsController.fetchedObjects.count;
}

#pragma mark - NSTableViewDelegate

-(NSView *)tableView : (NSTableView *)tableView viewForTableColumn : (NSTableColumn *)tableColumn row
                     : (NSInteger)row {
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
  
  Track *track = self.fetchedResultsController.fetchedObjects[row];
  BOOL isPlaying = self.currentTrack.objectID == track.objectID;
  
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

-(NSString *)formatTime : (NSTimeInterval)seconds {
  NSInteger mins = (NSInteger)seconds / 60;
  NSInteger secs = (NSInteger)seconds % 60;
  return [NSString stringWithFormat:@"%ld:%02ld", mins, secs];
}

-(CGFloat)tableView : (NSTableView *)tableView heightOfRow : (NSInteger)row {
  return 24.0;
}

-(void)tableView : (NSTableView *)tableView didClickTableColumn : (NSTableColumn *)tableColumn {
  NSString *columnIdentifier = tableColumn.identifier;
  NSMutableArray<NSSortDescriptor *> *sortDescriptors = [NSMutableArray array];
  
  NSArray<NSSortDescriptor *> *existingDescriptors =
  [self.fetchedResultsController.fetchRequest.sortDescriptors copy];
  
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

-(BOOL)isSortDescriptorForKey : (NSString *)key ascendingInArray : (NSArray<NSSortDescriptor *> *)descriptors {
  for (NSSortDescriptor *descriptor in descriptors) {
    if ([descriptor.key isEqualToString:key]) {
      return descriptor.ascending;
    }
  }
  return NO;
}

-(void)reloadData {
  [self.tableView reloadData];
  [self selectRowForTrack:self.currentTrack scroll:NO];
}

#pragma mark - Private Helpers

-(void)selectRowForTrack : (Track *)track scroll : (BOOL)scroll {
  if (track == nil) {
    [self.tableView deselectAll:nil];
    return;
  }
  
  NSUInteger rowIndex = [self.fetchedResultsController.fetchedObjects
                         indexOfObjectPassingTest:^BOOL(Track *obj, NSUInteger _, BOOL *stop) {
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

-(void)updateFetchedResultsControllerForCurrentPlaylist {
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

-(void)tableViewClicked : (id)sender {
  if (self.tableView.selectedRow >= 0) {
    NSArray<Track *> *tracks = self.fetchedResultsController.fetchedObjects;
    Track *track = tracks[self.tableView.selectedRow];
    
    [[PlaybackManager sharedManager] updateQueue:tracks];
    [[PlaybackManager sharedManager] playTrack:track];
  }
}

-(void)importURLs : (NSArray<NSURL *> *)urls {
  [TrackService importAudioFilesAtURLs:urls withPlaylist:self.currentPlaylist];
}

-(void)importURL : (NSURL *)url {
  [[TrackService findOrInsertByURL:url
                          playlist:self.currentPlaylist] continueWithSuccessBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      [[PlaybackManager sharedManager] playTrack:track];
    }
    return nil;
  }];
}

#pragma mark - Right-Click Menu

-(BOOL)validateMenuItem : (NSMenuItem *)menuItem {
  if ([menuItem.identifier isEqualToString:@"RemoveFromPlaylist"] && !self.currentPlaylist) {
    return NO;
  }
  return YES;
}

-(IBAction)showInFinderAction : (id)sender {
  Track *track = [self getClickedTrack];
  if (!track) {
    return;
  }
  
  NSURL *url = [NSURL fileURLWithPath:track.fileURL];
  if (!url) {
    NSLog(@"Error finding url");
  } else {
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ url ]];
  }
}

-(nullable Track *)getClickedTrack {
  NSInteger clickedRow = [self.tableView clickedRow];
  if (clickedRow < 0) {
    return nil;
  }
  
  return [self.fetchedResultsController.fetchedObjects objectAtIndex:clickedRow];
}

-(IBAction)removeFromPlaylistAction : (id)sender {
  Track *track = [self getClickedTrack];
  if (!track || !self.currentPlaylist) {
    return;
  }
  
  [[PlaylistDataStore removeFromPlaylist:self.currentPlaylist
                                   track:track] continueWithBlock:^id(BFTask<BFVoid> *task) {
    if (task.error) {
      NSLog(@"Error removing track from playlist: %@", task.error);
    }
    return nil;
  }];
}
-(IBAction)deleteAction : (id)sender {
}

@end
