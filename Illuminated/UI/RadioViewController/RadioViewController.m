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

// RadioViewController.m
#import "RadioViewController.h"
#import "AppPlaybackManager.h"
#import "RadioPlaybackController.h"
#import "RadioStation+PlaybackItem.h"

typedef NSString *RadioColumn;
static RadioColumn const RadioColumnName = @"NameColumn";
static RadioColumn const RadioColumnCountry = @"CountryColumn";
static RadioColumn const RadioColumnCodec = @"CodecColumn";
static RadioColumn const RadioColumnBitrate = @"BitrateColumn";
static RadioColumn const RadioColumnFavorite = @"FavoriteColumn";

#pragma mark - Private Interface

@interface RadioViewController () <NSFetchedResultsControllerDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property(nonatomic, strong) RadioBrowserClient *radioClient;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

// Keep track of current station for UI highlighting
@property(nonatomic, strong) RadioStation *currentRadioStation;

// KVO tokens
@property(nonatomic, strong) NSMutableArray *kvoTokens;

@end

#pragma mark - Implementation

@implementation RadioViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _radioClient = [[RadioBrowserClient alloc] init];
        _fetchedResultsController = [RadioStationDataStore fetchedResultsController];
        _kvoTokens = [NSMutableArray array];
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

- (void)setupKVO {
    AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew;
    
    [manager addObserver:self
                      forKeyPath:@"currentStation"
                         options:options
                         context:nil];
    
    [manager addObserver:self
                      forKeyPath:@"currentStreamTitle"
                         options:options
                         context:nil];
    
    [manager addObserver:self
                      forKeyPath:@"isPlaying"
                         options:options
                         context:nil];
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
            }
            else if ([keyPath isEqualToString:@"currentStreamTitle"]) {
                NSString *streamTitle = [AppPlaybackManager sharedManager].currentStreamTitle;
                NSLog(@"Now playing on radio: %@", streamTitle);
            }
        });
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

- (void)setupFetchedResultsController {
    self.fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"RadioViewController: Error loading radio stations: %@", error.localizedDescription);
    }
}

#pragma mark - Actions

- (void)tableViewDoubleClicked:(id)sender {
    NSInteger selectedRow = self.tableView.selectedRow;
    if (selectedRow < 0) return;
    
    NSArray<RadioStation *> *radioStations = self.fetchedResultsController.fetchedObjects;
    RadioStation *selectedStation = radioStations[selectedRow];
    
    // Check if this station is already playing
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
        [RadioStationDataStore updateIsFavoriteForRadioWithObjectID:station.objectID
                                                         isFavorite:!station.isFavorite];
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
    
    RadioStation *station = self.fetchedResultsController.fetchedObjects[row];
    AppPlaybackManager *manager = [AppPlaybackManager sharedManager];
    
    BOOL isPlaying = [manager.currentStation.objectID isEqual:station.objectID] && manager.isPlaying;

    NSString *columnIdentifier = tableColumn.identifier;
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:columnIdentifier owner:self];
    if (cell == nil) {
        cell = [[NSTableCellView alloc] init];
        cell.identifier = columnIdentifier;
        
        if ([columnIdentifier isEqualToString:RadioColumnFavorite]) {
            NSButton *button = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"heart"
                                                                     accessibilityDescription:nil]
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
        } else {
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
    }
    
    // Update favorite button state
    if ([columnIdentifier isEqualToString:RadioColumnFavorite]) {
        NSButton *button = cell.subviews.firstObject;
        button.image = [NSImage imageWithSystemSymbolName:station.isFavorite ? @"heart.fill" : @"heart"
                                  accessibilityDescription:nil];
        button.contentTintColor = station.isFavorite ? [NSColor systemRedColor] : [NSColor secondaryLabelColor];
    } else {
        // Configure text fields
        if ([columnIdentifier isEqualToString:RadioColumnName]) {
            cell.textField.alignment = NSTextAlignmentLeft;
            cell.textField.stringValue = station.name ?: @"";
        } else if ([columnIdentifier isEqualToString:RadioColumnCountry]) {
            cell.textField.alignment = NSTextAlignmentCenter;
            cell.textField.stringValue = station.country ?: station.countryCode ?: @"";
        } else if ([columnIdentifier isEqualToString:RadioColumnCodec]) {
            cell.textField.alignment = NSTextAlignmentCenter;
            cell.textField.stringValue = station.codec ?: @"unknown";
        } else if ([columnIdentifier isEqualToString:RadioColumnBitrate]) {
            cell.textField.alignment = NSTextAlignmentRight;
            cell.textField.stringValue = station.bitrate ? [NSString stringWithFormat:@"%@", station.bitrate] : @"";
        }
        
        // Highlight currently playing station
        cell.textField.font = isPlaying ? [NSFont boldSystemFontOfSize:13] : [NSFont systemFontOfSize:13];
        
        // Optionally add a small playing indicator
        if (isPlaying && [columnIdentifier isEqualToString:RadioColumnName]) {
            // Could add a speaker icon or something
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 24.0;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    // Handle sorting if needed
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
