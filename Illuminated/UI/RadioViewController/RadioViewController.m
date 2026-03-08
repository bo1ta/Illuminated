//
//  RadioViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioViewController.h"
#import "RBStation.h"
#import "RadioBrowserClient.h"
#import "RadioService.h"
#import "RadioStation.h"
#import "RadioStationDataStore.h"
#import "PlayerBarViewController.h"

#pragma mark - Constants

typedef NSString *RadioColumn;
static RadioColumn const RadioColumnName = @"NameColumn";
static RadioColumn const RadioColumnCountry = @"CountryColumn";
static RadioColumn const RadioColumnCodec = @"CodecColumn";
static RadioColumn const RadioColumnBitrate = @"BitrateColumn";

NSString *const RadioStationTitleDidChangeNotification = @"RadioStreamTitleDidChangeNotification";
NSString *const RadioStationDidChangeNotification = @"RadioStationDidChangeNotification";
NSString *const RadioStationWillStartPlayingNotification = @"RadioStationWillStartPlayingNotification";

NSString *const RadioStationTitleUserInfoKey = @"RadioStationTitleUserInfoKey";
NSString *const RadioStationStreamTitleUserInfoKey = @"RadioStationStreamTitleUserInfoKey";

NSString *const RadioStreamMetadataIcyIdentifier = @"icy/StreamTitle";

#pragma mark - Private Interface

@interface RadioViewController ()

@property (weak) IBOutlet NSTableView *tableView;

@property(nonatomic, strong) RadioBrowserClient *radioClient;
@property(strong, nullable) AVPlayer *streamPlayer;
@property(strong, nullable) id timeObserver;
@property(strong, nullable) AVPlayerItemMetadataOutput *metadataOutput;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property(nonatomic, assign) BOOL isPlaying;

@property(nonatomic, strong) RadioStation *currentRadioStation;

@end

#pragma mark - Implementation

@implementation RadioViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _radioClient = [[RadioBrowserClient alloc] init];
    _fetchedResultsController = [RadioStationDataStore fetchedResultsController];
    _isPlaying = NO;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.doubleAction = @selector(tableViewClicked:);
  
  self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  self.view.translatesAutoresizingMaskIntoConstraints = YES;
  
  [self setupFetchedResultsController];
  [self setupObservers];
  [self loadData];
}

- (void)setupObservers {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(stopRadioStream)
                 name:PlaybackSourceDidChangeToLibraryNotification
               object:nil];
  [center addObserver:self
             selector:@selector(togglePlayPause)
                 name:PlaybackDidToggleNotification
               object:nil];
}

- (void)loadData {
  [[RadioService getRadioStations] continueWithBlock:^id(BFTask<NSArray<RadioStation *> *> *task) {
    if (task.error) {
      NSLog(@"Error listing radio stations: %@", task.error.localizedDescription);
    } else {
      RadioStation *station = task.result.firstObject;
      if (station) {
        [self playRadioStation:station];
      }
    }
    return nil;
  }];
}

- (void)setupFetchedResultsController {
  self.fetchedResultsController.delegate = self;
  
  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
    NSLog(@"RadioViewController: Error loading radio stations for fetched results: %@", error.localizedDescription);
  }
}

- (void)playRadioStation:(RadioStation *)radioStation {
  NSURL *url = [NSURL URLWithString:radioStation.url];
  
  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
  [self setupMetadataOutputForPlayerItem:playerItem];
  
  self.streamPlayer = [AVPlayer playerWithPlayerItem:playerItem];
  [self addPlayerObservers];
  [self.streamPlayer play];
  
  if (radioStation.serverIDFallback) {
    [RadioService increaseClickCountForStationID:radioStation.serverIDFallback];
  }
  
  self.currentRadioStation = radioStation;
}

- (void)togglePlayPause {
    if (!self.streamPlayer) return;
    
    if (self.isPlaying) {
        [self.streamPlayer pause];
    } else {
        [self.streamPlayer play];
    }
    self.isPlaying = !self.isPlaying;
}

- (void)stopRadioStream {
  if (self.streamPlayer) {
    AVPlayerItem *playerItem = self.streamPlayer.currentItem;
    if (playerItem && self.metadataOutput) {
      [playerItem removeOutput:self.metadataOutput];
    }
    
    [self removePlayerObservers];
    [self.streamPlayer pause];
    self.streamPlayer = nil;
    self.metadataOutput = nil;
    self.isPlaying = NO;
  }
}

#pragma mark - Observers

- (void)addPlayerObservers {
  [self.streamPlayer addObserver:self
                      forKeyPath:@"status"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
}

- (void)removePlayerObservers {
  @try {
    [self.streamPlayer removeObserver:self forKeyPath:@"status"];
  } @catch (NSException *exception) {
    NSLog(@"RemovePlayerObservers Exception: Failed removing observer. Maybe it wasn't added?");
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.streamPlayer && [keyPath isEqualToString:@"status"]) {
        if (self.streamPlayer.status == AVPlayerStatusFailed) {
            [self handleStreamFailure];
        } else if (self.streamPlayer.status == AVPlayerStatusReadyToPlay) {
          self.isPlaying = YES;
          dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:RadioStationStreamTitleUserInfoKey object:nil userInfo:@{RadioStationTitleUserInfoKey: self.currentRadioStation.name}];
          });
        }
    }
}

- (void)handleStreamFailure {
    [self stopRadioStream];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self presentError:[NSError errorWithDomain:@"RadioViewControllerError" code:-100 userInfo:@{NSLocalizedDescriptionKey: @"Failed to load radio station. Please try another."}]];
    });
}

- (void)setupMetadataOutputForPlayerItem:(AVPlayerItem *)playerItem {
    self.metadataOutput = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
    
    [self.metadataOutput setDelegate:self queue:dispatch_get_main_queue()];
    
    [playerItem addOutput:self.metadataOutput];
}

- (void)tableViewClicked:(id)sender {
  if (self.tableView.selectedRow >= 0) {
    NSArray<RadioStation *> *radioStations = self.fetchedResultsController.fetchedObjects;
    RadioStation *radioStation = radioStations[self.tableView.selectedRow];

    [self playRadioStation:radioStation];
  }
}

#pragma mark - AVPlayerItemMetadataOutputPushDelegate

- (void)metadataOutput:(AVPlayerItemMetadataOutput *)output
     didOutputTimedMetadataGroups:(NSArray<AVTimedMetadataGroup *> *)groups
           fromPlayerItemTrack:(AVPlayerItemTrack *)track {
    
    for (AVTimedMetadataGroup *group in groups) {
        for (AVMetadataItem *item in group.items) {
            [self processMetadataItem:item];
        }
    }
}

- (void)processMetadataItem:(AVMetadataItem *)item {
  NSLog(@"Metadata - identifier: %@, key: %@, value: %@",
        item.identifier, item.key, item.stringValue);
  
  NSString *value = item.stringValue;
  if (!value)  {
    return;
  }
  
  if ([item.identifier isEqualToString:RadioStreamMetadataIcyIdentifier]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:RadioStationStreamTitleUserInfoKey object:nil userInfo:@{RadioStationStreamTitleUserInfoKey: value}];
  }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  [self.tableView reloadData];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return self.fetchedResultsController.fetchedObjects.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
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

  RadioStation *station = self.fetchedResultsController.fetchedObjects[row];
  BOOL isPlaying = self.currentRadioStation.objectID == station.objectID;
  
  if ([columnIdentifier isEqualToString:RadioColumnName]) {
    cell.textField.alignment = NSTextAlignmentLeft;
    cell.textField.stringValue = station.name;
  } else if ([columnIdentifier isEqualToString:RadioColumnCountry]) {
    cell.textField.alignment = NSTextAlignmentCenter;
    cell.textField.stringValue = station.country ?: station.countryCode;
  } else if ([columnIdentifier isEqualToString:RadioColumnCodec]) {
    cell.textField.alignment = NSTextAlignmentCenter;
    cell.textField.stringValue = station.codec ?: @"unknown";
  } else if ([columnIdentifier isEqualToString:RadioColumnBitrate]) {
    cell.textField.alignment = NSTextAlignmentRight;
    cell.textField.intValue = station.bitrate.intValue;
  }
  
  cell.textField.font = isPlaying ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:13];
  
  return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  return 24.0;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
  NSString *columnIdentifier = tableColumn.identifier;
}

@end
