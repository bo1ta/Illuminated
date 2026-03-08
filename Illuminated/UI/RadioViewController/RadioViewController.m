//
//  RadioViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioViewController.h"
#import "RBStation.h"
#import "RadioBrowserClient.h"
#import <AVFoundation/AVFoundation.h>
#import "RadioService.h"
#import "RadioStation.h"
#import "RadioStationDataStore.h"

#pragma mark - Constants

typedef NSString *RadioColumn;
static RadioColumn const RadioColumnName = @"NameColumn";
static RadioColumn const RadioColumnCountry = @"CountryColumn";
static RadioColumn const RadioColumnCodec = @"CodecColumn";
static RadioColumn const RadioColumnBitrate = @"BitrateColumn";

#pragma mark - Private Interface

@interface RadioViewController ()

@property (weak) IBOutlet NSTableView *tableView;

@property(nonatomic, strong) RadioBrowserClient *radioClient;
@property(strong, nullable) AVPlayer *streamPlayer;
@property(strong, nullable) id timeObserver;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property(nonatomic, strong) RadioStation *currentRadioStation;

@end

#pragma mark - Implementation

@implementation RadioViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _radioClient = [[RadioBrowserClient alloc] init];
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
  [self loadData];
}

- (void)loadData {
  [[RadioService getRadioStations] continueWithBlock:^id(BFTask<NSArray<RadioStation *> *> *task) {
    if (task.error) {
      NSLog(@"Error listing radio stations: %@", task.error.localizedDescription);
    } else {
      RadioStation *station = task.result.firstObject;
      if (station) {
        NSLog(@"Station with URL: %@", station.url);
        NSURL *url = [NSURL URLWithString:station.url];
        [self playStreamURL:url];
      }
    }
    return nil;
  }];
}

- (void)setupFetchedResultsController {
  _fetchedResultsController = [RadioStationDataStore fetchedResultsController];
  _fetchedResultsController.delegate = self;
  
  NSError *error = nil;
  if (![self.fetchedResultsController performFetch:&error]) {
    NSLog(@"RadioViewController: Error loading radio stations for fetched results: %@", error.localizedDescription);
  }
}

- (void)playStreamURL:(NSURL *)url {
  self.streamPlayer = [[AVPlayer alloc] initWithURL:url];
  [self.streamPlayer play];
}

- (void)tableViewClicked:(id)sender {
  if (self.tableView.selectedRow >= 0) {
    NSArray<RadioStation *> *radioStations = self.fetchedResultsController.fetchedObjects;
    RadioStation *radioStation = radioStations[self.tableView.selectedRow];

    [self playStreamURL:[NSURL URLWithString:radioStation.url]];
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
