//
//  PlayerBarViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, PlaybackSource) {
  PlaybackSourceRadio,
  PlaybackSourceLibrary,
};

extern NSString *const PlaybackSourceDidChangeToLibraryNotification;
extern NSString *const PlaybackDidToggleNotification;

NS_ASSUME_NONNULL_BEGIN

@interface PlayerBarViewController : NSViewController

@end

NS_ASSUME_NONNULL_END
