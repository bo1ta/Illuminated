//
//  MusicViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "MusicViewController.h"
#import "Album.h"
#import "Artist.h"
#import "PlaybackManager.h"
#import "CoreDataStore.h"
#import "TrackImportService.h"
#import "Playlist.h"
#import "Track.h"
#import "SidebarViewController.h"

@interface MusicViewController ()

@property(atomic, strong) NSArray<Track *> *tracks;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong) TrackImportService *importService;
@property(nonatomic, strong, nullable) Playlist *currentPlaylist;

@end

@implementation MusicViewController

- (TrackImportService *)importService {
  if (!_importService) {
    _importService = [[TrackImportService alloc] init];
  }
  return _importService;
}

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
}

- (void)selectCurrentTrack {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.tableView reloadData];
  });
  
  Track *playingTrack = [[PlaybackManager sharedManager] currentTrack];
  if (playingTrack.bpm <= 0) {
    NSURL *currentURL = [[PlaybackManager sharedManager] currentPlaybackURL];
    [[BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id {
      return [self.importService analyzeBPMForTrackURL:currentURL];
    }] continueOnMainThreadWithBlock:^id(BFTask<Track *> *task) {
      if (!task.error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PlaybackManagerTrackDidChangeNotification object:nil];
      }
      return task;
    }];
  }
}

- (void)sidebarSelectionDidChange:(NSNotification *)notification {
  id playlistObject = notification.userInfo[@"playlist"];
  
  if ([playlistObject isKindOfClass:[Playlist class]]) {
     self.currentPlaylist = (Playlist *)playlistObject;
   } else {
     self.currentPlaylist = nil; // "All Music" selected
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

  if (resolvedURLs.count == 0) return NO;

  [self importURL:resolvedURLs.firstObject];

  return YES;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  self.tracks = (NSArray<Track *> *)[controller fetchedObjects];
  [self.tableView reloadData];
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
  
  if ([columnIdentifier isEqualToString:@"NumberColumn"]) {
    cell.textField.alignment = NSTextAlignmentCenter;
    if (isPlaying) {
      cell.textField.stringValue = @"▶";
    } else {
      cell.textField.stringValue = [NSString stringWithFormat:@"%ld", (long)row + 1];
    }
  } else if ([columnIdentifier isEqualToString:@"SongColumn"]) {
    cell.textField.stringValue = track.title;
    cell.textField.alignment = NSTextAlignmentLeft;
  } else if ([columnIdentifier isEqualToString:@"ArtistColumn"]) {
    cell.textField.stringValue = track.artist.name ?: @"Unknown";
    cell.textField.alignment = NSTextAlignmentLeft;
  } else if ([columnIdentifier isEqualToString:@"AlbumColumn"]) {
    cell.textField.stringValue = track.album.title ?: @"Unknown";
    cell.textField.alignment = NSTextAlignmentLeft;
  } else if ([columnIdentifier isEqualToString:@"TimeColumn"]) {
    cell.textField.stringValue = [self formatTime:track.duration];
    cell.textField.alignment = NSTextAlignmentRight;
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

#pragma mark - Private Helpers

- (void)updateFetchedResultsControllerForCurrentPlaylist {
  NSPredicate *predicate = nil;
  if (self.currentPlaylist != nil) {
    predicate = [NSPredicate predicateWithFormat:@"ANY playlists == %@", self.currentPlaylist];
  }
  
  self.fetchedResultsController.fetchRequest.predicate = predicate;
  [self.fetchedResultsController performFetch:nil];
  
  self.tracks = (NSArray<Track *> *)[self.fetchedResultsController fetchedObjects];
  [self.tableView reloadData];
}

- (void)tableViewClicked:(id)sender {
  if (self.tableView.selectedRow >= 0) {
    Track *selectedTrack = self.tracks[self.tableView.selectedRow];

    [[PlaybackManager sharedManager] updateQueue:self.tracks];
    [[PlaybackManager sharedManager] playTrack:selectedTrack];
  }
}

- (void)importURL:(NSURL *)url {
  [[[[CoreDataStore reader] trackWithURL:url] continueWithBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      return task;
    }
    return [self.importService importAudioFileAtURL:url withPlaylist:self.currentPlaylist];
  }] continueWithSuccessBlock:^id(BFTask<Track *> *task) {
    Track *track = task.result;
    if (track) {
      [[PlaybackManager sharedManager] playTrack:track];
    }
    return nil;
  }];
}

@end
