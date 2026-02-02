//
//  MainWindowController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ToolbarSearchDidChangeNotification;
extern NSString *const ToolbarSearchUserInfo;

@interface MainWindowController : NSWindowController

- (void)openAudioFileURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
