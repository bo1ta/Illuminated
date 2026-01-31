//
//  MusicViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Cocoa/Cocoa.h>

@class MusicViewController;

NS_ASSUME_NONNULL_BEGIN

@interface MusicViewController
    : NSViewController<NSTableViewDataSource, NSTableViewDelegate, NSFetchedResultsControllerDelegate>

@property(weak) IBOutlet NSTableView *tableView;

@end

NS_ASSUME_NONNULL_END
