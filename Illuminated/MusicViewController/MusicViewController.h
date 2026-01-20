//
//  MusicViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import "CoreDataStore.h"
#import "TrackImportService.h"
#import <Cocoa/Cocoa.h>

@class MusicViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol MusicViewControllerDelegate<NSObject>
- (void)musicViewController:(MusicViewController *)controller didSelectTrack:(Track *)track;
@end

@interface MusicViewController
    : NSViewController<NSTableViewDataSource, NSTableViewDelegate, NSFetchedResultsControllerDelegate>

@property(nonatomic, weak) id<MusicViewControllerDelegate> delegate;
@property(weak) IBOutlet NSTableView *tableView;
@property(atomic, strong) NSArray<Track *> *tracks;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic, strong) TrackImportService *importService;

@end

NS_ASSUME_NONNULL_END
