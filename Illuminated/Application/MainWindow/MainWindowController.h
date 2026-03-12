//
//  MainWindowController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainWindowController : NSWindowController

- (void)openAudioFileURL:(NSURL *)url;
- (void)openAudioFileURLs:(NSArray<NSURL *> *)urls;

@end

NS_ASSUME_NONNULL_END
