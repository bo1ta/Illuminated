//
//  MusicViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "MusicViewController.h"
#import "PlaybackManager.h"

@interface MusicViewController ()

@property(atomic, strong) NSArray<Track *> *tracks;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong) TrackImportService *importService;

@end

@implementation MusicViewController

- (TrackImportService *)importService {
  if (!_importService) {
    _importService = [[TrackImportService alloc] init];
  }
  return _importService;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.doubleAction = @selector(tableViewClicked:);

  [self.tableView registerForDraggedTypes:@[ NSPasteboardTypeFileURL ]];
  self.tableView.draggingDestinationFeedbackStyle = NSTableViewDraggingDestinationFeedbackStyleRegular;

  [self setupFetchedResultsController];
}

- (void)tableViewClicked:(id)sender {
  if (self.tableView.selectedRow >= 0) {
    Track *selectedTrack = self.tracks[self.tableView.selectedRow];

    [[PlaybackManager sharedManager] updateQueue:self.tracks];
    [[PlaybackManager sharedManager] playTrack:selectedTrack];
  }
}

- (void)setupFetchedResultsController {
  _fetchedResultsController = [[CoreDataStore readOnlyStore] fetchedResultsControllerForEntity:EntityNameTrack
                                                                                     predicate:nil
                                                                               sortDescriptors:nil];
  _fetchedResultsController.delegate = self;

  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
  } else {
    self.tracks = (NSArray<Track *> *)[self.fetchedResultsController fetchedObjects];
  }
}

#pragma mark - Drag & Drop methods

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

  if (fileURLs.count == 0)
    return NO;

  NSMutableArray<NSURL *> *resolvedURLs = [NSMutableArray array];
  NSSet *audioExtensions = [NSSet setWithArray:@[ @"mp3", @"m4a", @"wav", @"aiff", @"flac", @"aac", @"ogg", @"wma" ]];

  for (NSURL *url in fileURLs) {
    NSURL *standardURL = [url filePathURL];

    NSString *extension = [[standardURL pathExtension] lowercaseString];
    if ([audioExtensions containsObject:extension]) {
      [resolvedURLs addObject:standardURL];
    }
  }

  if (resolvedURLs.count == 0)
    return NO;

  [self importURL:resolvedURLs.firstObject];

  return YES;
}

- (void)importURL:(NSURL *)url {
  [[[BFTask taskWithDelay:0] continueWithExecutor:[BFExecutor defaultExecutor]
                                        withBlock:^id(BFTask<BFVoid> *_) {
                                          return [self.importService importAudioFileAtURL:url];
                                        }] continueWithBlock:^id(BFTask<Track *> *task) {
    if (task.error) {
      NSLog(@"Final Task Error: %@", task.error);
    } else {
      Track *track = task.result;
      if (track) {
        [[PlaybackManager sharedManager] playTrack:track];
      }
    }
    return nil;
  }];
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
  if ([columnIdentifier isEqualToString:@"NumberColumn"]) {
    cell.textField.stringValue = [NSString stringWithFormat:@"%ld", (long)row];
    cell.textField.alignment = NSTextAlignmentCenter;
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
    cell.textField.stringValue = [NSString stringWithFormat:@"%f", track.duration];
    cell.textField.alignment = NSTextAlignmentRight;
  }

  return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  return 24.0;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
}

@end
