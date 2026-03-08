//
//  RadioViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioViewController.h"
#import "RBStation.h"
#import "RadioBrowserClient.h"
#import <AVFoundation/AVFoundation.h>
#import "RadioService.h"
#import "RadioStation.h"

@interface RadioViewController ()
@property(weak) IBOutlet NSOutlineView *outlineView;

@property(nonatomic, strong) RadioBrowserClient *radioClient;
@property(strong, nullable) AVPlayer *streamPlayer;
@property(strong, nullable) id timeObserver;

@end

@implementation RadioViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _radioClient = [[RadioBrowserClient alloc] init];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[RadioService getRadioStations] continueWithBlock:^id(BFTask<NSArray<RadioStation *> *> *task) {
    if (task.error) {
      NSLog(@"Error listing radio stations: %@", task.error.localizedDescription);
    } else {
      RadioStation *station = task.result.firstObject;
      if (station) {
        NSLog(@"Station with URL: %@", station.url);
        NSURL *url = [NSURL URLWithString:station.url];
        [self playStreamURL:url];
      }
    }
    return nil;
  }];
}

- (void)playStreamURL:(NSURL *)url {
  self.streamPlayer = [[AVPlayer alloc] initWithURL:url];
  [self.streamPlayer play];
}

@end
