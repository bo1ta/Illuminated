//
//  RadioViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

#pragma mark - Constants

extern NSString *const RadioStreamTitleDidChangeNotification;
extern NSString *const RadioStationDidChangeNotification;
extern NSString *const RadioStationWillStartPlayingNotification;

extern NSString *const RadioStationTitleUserInfoKey;
extern NSString *const RadioStationStreamTitleUserInfoKey;

#pragma mark - RadioViewController

NS_ASSUME_NONNULL_BEGIN

@interface RadioViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate, NSFetchedResultsControllerDelegate, AVPlayerItemMetadataOutputPushDelegate>

@end

NS_ASSUME_NONNULL_END
