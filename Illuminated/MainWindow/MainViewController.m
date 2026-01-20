//
//  MainViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "MainViewController.h"
#import "CoreDataStore.h"

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize artists;

- (void)viewDidLoad {
  [super viewDidLoad];

  [self setupTableView];
  [self loadArtists];
}

- (void)setupTableView {
  self.tableView.style = NSTableViewStyleSourceList;
  [self.tableView setGridStyleMask:NSTableViewGridNone];
  self.tableView.rowHeight = 32.0;

  self.tableView.dataSource = self;
  self.tableView.delegate = self;
}

- (void)loadArtists {
  [[[CoreDataStore readOnlyStore] allArtists]
      continueWithBlock:^id _Nullable(BFTask<NSArray<Artist *> *> *_Nonnull task) {
        if (task.error) {
          NSLog(@"Error getting artists: %@", task.error.localizedDescription);
          return nil;
        }

        [self setArtists:task.result];
        [[self tableView] reloadData];
        return nil;
      }];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return self.artists.count;
}

- (NSView *)tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row {
  NSTableCellView *cell = [tableView makeViewWithIdentifier:@"ArtistCell" owner:self];

  if (!cell) {
    cell = [[NSTableCellView alloc] init];
    cell.identifier = @"ArtistCell";

    NSTextField *textField = [[NSTextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.backgroundColor = [NSColor clearColor];
    textField.bordered = NO;
    textField.editable = NO;
    textField.font = [NSFont systemFontOfSize:13];
    [cell addSubview:textField];
    cell.textField = textField;

    NSDictionary *views = @{@"textField" : textField};
    [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[textField]-8-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[textField]-6-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
  }

  Artist *artist = self.artists[row];
  cell.textField.stringValue = artist.name ?: @"Unknown Artist";

  return cell;
}

@end
