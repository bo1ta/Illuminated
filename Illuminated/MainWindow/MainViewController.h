//
//  MainViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <Cocoa/Cocoa.h>
#import "Artist.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (strong) NSArray<Artist *> *artists;

@end

NS_ASSUME_NONNULL_END
