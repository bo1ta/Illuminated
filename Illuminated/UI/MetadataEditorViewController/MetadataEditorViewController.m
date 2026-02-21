//
//  MetadataEditorViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 20.02.2026.
//

#import "MetadataEditorViewController.h"
#import "Album.h"
#import "Artist.h"
#import "BFTask.h"
#import "Track.h"
#import "TrackService.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface MetadataEditorViewController ()

@property(weak) IBOutlet NSImageView *artworkImageView;
@property(weak) IBOutlet NSTextField *titleTextField;
@property(weak) IBOutlet NSTextField *artistTextField;
@property(weak) IBOutlet NSTextField *albumTextField;
@property(weak) IBOutlet NSTextField *genreTextField;
@property(weak) IBOutlet NSTextField *yearTextField;

@property(nonatomic, strong) Track *track;
@property(nonatomic, strong) NSString *originalArtworkPath;
@property(nonatomic, strong) NSImage *selectedDisplayImage;

@end

@implementation MetadataEditorViewController

- (instancetype)initWithTrack:(Track *)track {
  self = [super init];
  if (self) {
    _track = track;
    _originalArtworkPath = track.album.artworkPath;
    _selectedDisplayImage = nil;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self populateData];
}

- (void)populateData {
  if (self.track.title) {
    [self.titleTextField setStringValue:self.track.title];
  }
  if (self.track.artist.name) {
    [self.artistTextField setStringValue:self.track.artist.name];
  }
  if (self.track.album.title) {
    [self.albumTextField setStringValue:self.track.album.title];
  }
  if (self.track.genre) {
    [self.genreTextField setStringValue:self.track.genre];
  }
  if (self.track.year) {
    [self.yearTextField setStringValue:[NSString stringWithFormat:@"%i", self.track.year]];
  }

  self.artworkImageView.image = [TrackService loadArtworkForTrack:self.track
                                              withPlaceholderSize:self.artworkImageView.bounds.size];
}

#pragma mark - IBActions

- (IBAction)saveAction:(id)sender {
  [[TrackService updateTrack:self.track
                   withTitle:self.titleTextField.stringValue
                  artistName:self.artistTextField.stringValue
                  albumTitle:self.albumTextField.stringValue
                  albumImage:self.selectedDisplayImage
                       genre:self.genreTextField.stringValue
                        year:self.yearTextField.intValue] continueOnMainThreadWithBlock:^id(BFTask *task) {
    if (task.error) {
      [self presentError:task.error];
    } else {
      if (self.selectedDisplayImage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ArtworkDidChangeNotification"
                                                            object:self.track.album];
      }
      [self dismissController:nil];
    }

    return nil;
  }];
}

- (IBAction)cancelAction:(id)sender {
  [self dismissController:nil];
}

- (IBAction)changeArtworkAction:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = YES;
  panel.canChooseDirectories = NO;
  panel.allowsMultipleSelection = NO;
  panel.allowedContentTypes = @[UTTypeImage];
  panel.message = @"Select an image for the album artwork";
  panel.prompt = @"Select";
  panel.title = @"Choose Cover Art";

  NSWindow *window = self.view.window;
  if (!window) {
    return;
  }

  [panel beginSheetModalForWindow:window
                completionHandler:^(NSModalResponse returnCode) {
                  if (returnCode == NSModalResponseOK) {
                    NSURL *selectedURL = panel.URLs.firstObject;
                    if (selectedURL) {
                      [self loadArtworkFromURL:selectedURL];
                    }
                  }
                }];
}

- (void)loadArtworkFromURL:(NSURL *)imageURL {
  NSImage *selectedImage = [[NSImage alloc] initWithContentsOfURL:imageURL];
  
  if (!selectedImage) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Invalid Image";
    alert.informativeText = @"The selected file could not be loaded as an image.";
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
    return;
  }
  
  NSImage *displayImage = [self resizeImage:selectedImage
                                     toSize:self.artworkImageView.bounds.size];
  
  self.artworkImageView.image = displayImage;
  self.selectedDisplayImage = displayImage;
}

- (NSImage *)resizeImage:(NSImage *)sourceImage toSize:(NSSize)size {
  NSImage *resizedImage = [[NSImage alloc] initWithSize:size];
  
  [resizedImage lockFocus];
  [sourceImage drawInRect:NSMakeRect(0, 0, size.width, size.height)
                 fromRect:NSZeroRect
                operation:NSCompositingOperationCopy
                 fraction:1.0];
  [resizedImage unlockFocus];
  
  return resizedImage;
}

@end
