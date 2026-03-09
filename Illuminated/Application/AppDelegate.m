//
//  AppDelegate.m
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "AppDelegate.h"
#import "CoreDataStore.h"
#import "TrackPlaybackController.h"
#import "FileExtensionHelper.h"
#import "MainWindowController.h"
#import "Track.h"

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

#pragma mark - MenuItem Actions

- (IBAction)openDocument:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = NO;
  panel.allowsMultipleSelection = NO;
  panel.allowedContentTypes = [FileExtensionHelper audioUTTypes];
  panel.message = @"Select a track";
  panel.prompt = @"Open";

  __weak AppDelegate *weakSelf = self;
  [panel beginSheetModalForWindow:self.mainWindowController.window completionHandler:^(NSModalResponse result) {
    
    NSURL *selectedFileURL = panel.URLs.firstObject;
    
    if (weakSelf && result == NSModalResponseOK && self.mainWindowController && selectedFileURL) {
      [weakSelf.mainWindowController openAudioFileURL:selectedFileURL];
      [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:selectedFileURL];
    }
  }];
}

- (IBAction)open:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = YES;
  panel.allowsMultipleSelection = YES;
  panel.allowedContentTypes = [FileExtensionHelper audioUTTypes];
  panel.message = @"Select a folder to import";
  panel.prompt = @"Import";

  __weak AppDelegate *weakSelf = self;
  [panel beginSheetModalForWindow:self.mainWindowController.window completionHandler:^(NSModalResponse result) {
    if (weakSelf && result == NSModalResponseOK && self.mainWindowController && panel.URLs.count > 0) {
      [weakSelf.mainWindowController openAudioFileURLs:[panel.URLs copy]];
    }
  }];
}

- (IBAction)showInFinderAction:(id)sender {
  Track *currentTrack = [[TrackPlaybackController sharedManager] currentTrack];
  if (currentTrack) {
    NSURL *url = [NSURL fileURLWithPath:currentTrack.fileURL];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ url ]];
  }
}

@end
