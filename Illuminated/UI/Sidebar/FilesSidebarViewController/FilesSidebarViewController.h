//
//  FilesSidebarViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface FilesSidebarViewController : NSViewController<NSOutlineViewDataSource, NSOutlineViewDelegate>

@end

extern NSString *const PasteboardItemTypeTrackImport;

NS_ASSUME_NONNULL_END
