//
//  MetadataEditorViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class Track;

@interface MetadataEditorViewController : NSViewController

- (instancetype)initWithTrack:(Track *)track;

@end

NS_ASSUME_NONNULL_END
