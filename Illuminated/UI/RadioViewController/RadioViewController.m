//
//  RadioViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 14.02.2026.
//

#import "RadioViewController.h"
#import "RadioStation.h"
#import "RadioBrowserClient.h"

@interface RadioViewController ()
@property(weak) IBOutlet NSOutlineView *outlineView;

@property(nonatomic, strong) RadioBrowserClient *radioClient;

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
  
  [[self.radioClient listAllStations] continueWithBlock:^id(BFTask<NSArray<RadioStation *> *> *task) {
    if (task.error) {
      NSLog(@"Error listing radio stations: %@", task.error.localizedDescription);
    } else {
      NSLog(@"Received a couple results: %@", task.result);
      RadioStation *station = task.result.firstObject;
      if (station) {
        NSLog(@"Station with URL: %@", station.url);
      }
    }
    return nil;
  }];
}

@end
