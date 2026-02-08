//
//  AppDelegate.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "AppDelegate.h"
#import "CoreDataStore.h"
#import "MainWindowController.h"

@interface AppDelegate ()

@property(strong) IBOutlet NSWindow *window;
@property(strong) MainWindowController *mainWindowController;
@property(strong) NSURL *pendingFileURL;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self.window close];
  self.window = nil;

  self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
  [self.mainWindowController.window center];
  [self.mainWindowController showWindow:nil];
  [self.mainWindowController.window makeKeyAndOrderFront:nil];

  if (self.pendingFileURL) {
    [self.mainWindowController openAudioFileURL:self.pendingFileURL];
    self.pendingFileURL = nil;
  }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
  return YES;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
  // Returns the NSUndoManager for the application. In this case, the manager returned is that of
  // the managed object context for the application.
  return [[[CoreDataStore shared] viewContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  return NSTerminateNow;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
  NSURL *url = [NSURL fileURLWithPath:filename];

  if (self.mainWindowController) {
    [self.mainWindowController openAudioFileURL:url];
  } else {
    // Window not ready yet, queue it
    self.pendingFileURL = url;
  }
  return YES;
}

- (void)importAudioURL:(NSURL *)audioURL bookmarkData:(NSData *)bookmarkData {
  
}

@end
