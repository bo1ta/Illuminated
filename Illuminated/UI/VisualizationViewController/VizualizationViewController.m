//
//  VizualizationViewController.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "VizualizationViewController.h"
#import "PlaybackManager.h"
#import "VisualizationPreset.h"
#import "VizualizationView.h"

@interface VizualizationViewController ()

@property(strong) IBOutlet VizualizationView *vizualizationView;

@end

@implementation VizualizationViewController

#pragma mark - Lifecycle

- (void)viewDidAppear {
  [super viewDidAppear];

  [self registerForAudioBufferChanges];
}

- (void)viewDidDisappear {
  [super viewDidDisappear];

  [[PlaybackManager sharedManager] unregisterAudioBufferCallback];
  [self.vizualizationView stopRendering];
}

#pragma mark - Audio Buffer Registration

- (void)registerForAudioBufferChanges {
  __weak typeof(self) weakSelf = self;

  [[PlaybackManager sharedManager]
      registerAudioBufferCallback:^(const float *_Nonnull monoData, AVAudioFrameCount length) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (!strongSelf) return;
        [strongSelf.vizualizationView updateAudioData:monoData length:length];
      }];

  [self.vizualizationView startRendering];
}

@end
