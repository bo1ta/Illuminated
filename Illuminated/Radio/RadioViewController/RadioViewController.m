//
//  RadioViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioViewController.h"
#import "AppPlaybackManager.h"
#import "PlayerBarViewController.h"
#import "RadioBrowserClient.h"
#import "RadioPlaybackController.h"
#import "RadioService.h"
#import "RadioStation.h"
#import "BFTask.h"
#import "RadioStationDataStore.h"
#import "RadioStationTag.h"

#pragma mark - Constants

typedef NSString *RadioColumn;
static RadioColumn const RadioColumnIndex = @"IndexColumn";
static RadioColumn const RadioColumnName = @"NameColumn";
static RadioColumn const RadioColumnCountry = @"CountryColumn";
static RadioColumn const RadioColumnClickCount = @"ClickCountColumn";
static RadioColumn const RadioColumnBitrate = @"BitrateColumn";
static RadioColumn const RadioColumnFavorite = @"FavoriteColumn";

#pragma mark - Private Interface

@interface RadioViewController ()<NSTableViewDataSource,
                                  NSTableViewDelegate,
                                  NSFetchedResultsControllerDelegate,
                                  AVPlayerItemMetadataOutputPushDelegate>

@property(weak) IBOutlet NSTableView *tableView;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property(nonatomic, strong) RadioStation *currentRadioStation;

@end

#pragma mark - Implementation

@implementation RadioViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _fetchedResultsController = [RadioStationDataStore fetchedResultsController];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.doubleAction = @selector(tableViewDoubleClicked:);

  self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  self.view.translatesAutoresizingMaskIntoConstraints = YES;

  [self setupFetchedResultsController];
  [self setupKVO];
  [self loadData];

  self.currentRadioStation = [AppPlaybackManager sharedManager].currentStation;
}

#pragma mark - Setup

- (void)setupFetchedResultsController {
  self.fetchedResultsController.delegate = self;

  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
    NSLog(@"RadioViewController: Error loading radio stations: %@", error.localizedDescription);
  }
}

- (void)loadData {
  [[RadioService getRadioStations] continueWithBlock:^id(BFTask<NSArray<RadioStation *> *> *task) {
    if (task.error) {
      NSLog(@"Error listing radio stations: %@", task.error.localizedDescription);
    } else {
    }
    return nil;
  }];
}

#pragma mark - KVO

- (void)setupKVO {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
  NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew;

  [manager addObserver:self forKeyPath:@"currentStation" options:options context:nil];

  [manager addObserver:self forKeyPath:@"currentStreamTitle" options:options context:nil];

  [manager addObserver:self forKeyPath:@"isPlaying" options:options context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

  if (object == [AppPlaybackManager sharedManager]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([keyPath isEqualToString:@"currentStation"]) {
        self.currentRadioStation = [AppPlaybackManager sharedManager].currentStation;
        [self.tableView reloadData];
      } else if ([keyPath isEqualToString:@"currentStreamTitle"]) {
        NSString *streamTitle = [AppPlaybackManager sharedManager].currentStreamTitle;
        NSLog(@"Now playing on radio: %@", streamTitle);
      }
    });
  }
}

#pragma mark - Actions

- (void)tableViewDoubleClicked:(id)sender {
  NSInteger selectedRow = self.tableView.selectedRow;
  if (selectedRow < 0) return;

  NSArray<RadioStation *> *radioStations = self.fetchedResultsController.fetchedObjects;
  RadioStation *selectedStation = radioStations[selectedRow];

  RadioStation *currentStation = [AppPlaybackManager sharedManager].currentStation;

  if ([currentStation.objectID isEqual:selectedStation.objectID]) {
    [[AppPlaybackManager sharedManager] togglePlayPause];
  } else {
    [[AppPlaybackManager sharedManager] playRadioStation:selectedStation];
  }
}

- (void)didFavoriteStation:(id)sender {
  NSInteger row = [self.tableView rowForView:sender];
  if (row < 0) return;

  RadioStation *station = self.fetchedResultsController.fetchedObjects[row];
  if (station) {
    [RadioStationDataStore updateIsFavoriteForRadioWithObjectID:station.objectID isFavorite:!station.isFavorite];
  }
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return self.fetchedResultsController.fetchedObjects.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  return 24.0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

  RadioStation *station = self.fetchedResultsController.fetchedObjects[row];
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];

  BOOL isPlaying = [manager.currentStation.objectID isEqual:station.objectID] && manager.isPlaying;

  NSString *columnIdentifier = tableColumn.identifier;

  NSTableCellView *cell = [tableView makeViewWithIdentifier:columnIdentifier owner:self];
  if (cell == nil) {
    cell = [[NSTableCellView alloc] init];
    cell.identifier = columnIdentifier;
  }

  if ([columnIdentifier isEqualToString:RadioColumnFavorite]) {
    NSButton *button = nil;
    for (NSView *view in cell.subviews) {
      if ([view isKindOfClass:[NSButton class]]) {
        button = (NSButton *)view;
        break;
      }
    }

    if (!button) {
      button = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"heart" accessibilityDescription:nil]
                                  target:self
                                  action:@selector(didFavoriteStation:)];
      button.translatesAutoresizingMaskIntoConstraints = NO;
      button.bordered = NO;
      [cell addSubview:button];

      [NSLayoutConstraint activateConstraints:@[
        [button.centerXAnchor constraintEqualToAnchor:cell.centerXAnchor],
        [button.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
        [button.widthAnchor constraintEqualToConstant:20],
        [button.heightAnchor constraintEqualToConstant:20]
      ]];
    }

    button.image = [NSImage imageWithSystemSymbolName:station.isFavorite ? @"heart.fill" : @"heart"
                             accessibilityDescription:nil];
    button.contentTintColor = station.isFavorite ? [NSColor systemRedColor] : [NSColor secondaryLabelColor];

  } else {
    if (!cell.textField) {
      NSTextField *textField = [[NSTextField alloc] init];
      textField.translatesAutoresizingMaskIntoConstraints = NO;
      textField.bordered = NO;
      textField.drawsBackground = NO;
      textField.editable = NO;
      textField.lineBreakMode = NSLineBreakByTruncatingTail;
      cell.textField = textField;
      [cell addSubview:textField];

      [NSLayoutConstraint activateConstraints:@[
        [textField.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:8],
        [textField.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-8],
        [textField.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor]
      ]];
    }

    if ([columnIdentifier isEqualToString:RadioColumnIndex]) {
      cell.textField.alignment = NSTextAlignmentCenter;
      cell.textField.stringValue = [NSString stringWithFormat:@"%ld", (long)row + 1];
    } else if ([columnIdentifier isEqualToString:RadioColumnName]) {
      cell.textField.alignment = NSTextAlignmentLeft;
      cell.textField.stringValue = station.name ?: @"";
    } else if ([columnIdentifier isEqualToString:RadioColumnCountry]) {
      cell.textField.alignment = NSTextAlignmentCenter;
      cell.textField.stringValue = station.country ?: station.countryCode ?: @"";
    } else if ([columnIdentifier isEqualToString:RadioColumnClickCount]) {
      cell.textField.alignment = NSTextAlignmentCenter;
      NSLog(@"Tags: %@", station.tags.anyObject);
      cell.textField.stringValue = [station.tags anyObject].name ?: @"";
    } else if ([columnIdentifier isEqualToString:RadioColumnBitrate]) {
      cell.textField.alignment = NSTextAlignmentRight;
      cell.textField.stringValue = station.bitrate ? [NSString stringWithFormat:@"%@", station.bitrate] : @"";
    }

    cell.textField.font = isPlaying ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:13];
  }

  return cell;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
  NSString *columnIdentifier = tableColumn.identifier;
  NSMutableArray<NSSortDescriptor *> *sortDescriptors = [NSMutableArray array];

  NSArray<NSSortDescriptor *> *existingDescriptors = [self.fetchedResultsController.fetchRequest.sortDescriptors copy];

  if ([columnIdentifier isEqualToString:RadioColumnName]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                ascending:![self isSortDescriptorForKey:@"name"
                                                                       ascendingInArray:existingDescriptors]]];
  } else if ([columnIdentifier isEqualToString:RadioColumnCountry]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"country"
                                                ascending:![self isSortDescriptorForKey:@"country"
                                                                       ascendingInArray:existingDescriptors]]];
  } else if ([columnIdentifier isEqualToString:RadioColumnClickCount]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"clickCount"
                                                ascending:![self isSortDescriptorForKey:@"clickCount"
                                                                       ascendingInArray:existingDescriptors]]];
  } else if ([columnIdentifier isEqualToString:RadioColumnBitrate]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"bitrate"
                                                ascending:![self isSortDescriptorForKey:@"bitrate"
                                                                       ascendingInArray:existingDescriptors]]];
  } else if ([columnIdentifier isEqualToString:RadioColumnFavorite]) {
    [sortDescriptors
        addObject:[NSSortDescriptor sortDescriptorWithKey:@"isFavorite"
                                                ascending:![self isSortDescriptorForKey:@"isFavorite"
                                                                       ascendingInArray:existingDescriptors]]];
  } else {
    return;
  }

  self.fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors;

  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
    NSLog(@"RadioViewController: Error performing fetch request. Error: %@", error);
    return;
  }

  [self.tableView reloadData];
}

- (BOOL)isSortDescriptorForKey:(NSString *)key ascendingInArray:(NSArray<NSSortDescriptor *> *)descriptors {
  for (NSSortDescriptor *descriptor in descriptors) {
    if ([descriptor.key isEqualToString:key]) {
      return descriptor.ascending;
    }
  }
  return NO;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView reloadData];
}

#pragma mark - Cleanup

- (void)dealloc {
  AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
  @try {
    [manager removeObserver:self forKeyPath:@"currentStation"];
    [manager removeObserver:self forKeyPath:@"currentStreamTitle"];
    [manager removeObserver:self forKeyPath:@"isPlaying"];
  } @catch (NSException *exception) {
    NSLog(@"Error removing observers: %@", exception);
  }
}

@end
