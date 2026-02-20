//
//  WaveformView.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "WaveformView.h"
#import "EZAudio.h"
#import "BFTask.h"
#import "EZAudioFile+Helpers.h"

@interface WaveformView ()

@property(nonatomic, strong) EZAudioFile *audioFile;
@property(nonatomic, strong) EZAudioPlot *audioPlot;

@property(nonatomic, strong) NSView *progressOverlayView;
@property(nonatomic, strong) NSView *needleView;

@end

@implementation WaveformView {
  NSTrackingArea *_trackingArea;
}

- (void)awakeFromNib {
  [super awakeFromNib];

  self.wantsLayer = YES;
  self.layer.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.2].CGColor;

  _audioPlot = [[EZAudioPlot alloc] initWithFrame:self.bounds];
  _audioPlot.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  _audioPlot.backgroundColor = [NSColor clearColor];
  _audioPlot.color = [NSColor colorWithCalibratedRed: 1.000 green: 1.000 blue: 1.000 alpha: 1];
  _audioPlot.plotType = EZPlotTypeBuffer;
  _audioPlot.shouldFill = YES;
  _audioPlot.shouldMirror = YES;
  _audioPlot.shouldOptimizeForRealtimePlot = NO;
  _audioPlot.waveformLayer.shadowOffset = CGSizeMake(0.0, -1.0);
  _audioPlot.waveformLayer.shadowRadius = 0.0;
  _audioPlot.waveformLayer.shadowColor = [NSColor colorWithCalibratedRed:0.069 green:0.543 blue:0.575 alpha:1].CGColor;
  _audioPlot.waveformLayer.shadowOpacity = 1.0;
  [self addSubview:_audioPlot];

  _progressOverlayView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, self.bounds.size.height)];
  _progressOverlayView.wantsLayer = YES;
  _progressOverlayView.layer.backgroundColor = [[NSColor systemBlueColor] colorWithAlphaComponent:0.3].CGColor;
  [self addSubview:_progressOverlayView];

  _needleView = [[NSView alloc] initWithFrame:NSMakeRect(-1, 0, 2, self.bounds.size.height)];
  _needleView.wantsLayer = YES;
  _needleView.layer.backgroundColor = [NSColor whiteColor].CGColor;
  [self addSubview:_needleView];
}

- (void)layout {
  [super layout];
  [self updateNeedlePosition];
}

- (void)setAudioURL:(NSURL *)audioURL {
  _audioURL = audioURL;
  if (!audioURL) {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.11f];
    [self.audioPlot clear];
    [CATransaction commit];
    return;
  }

  self.audioFile = [EZAudioFile audioFileWithURL:audioURL];

  [CATransaction begin];
  [CATransaction setAnimationDuration:0.11f];
  [self.audioPlot clear];
  [CATransaction commit];
  
  BFTask<EZAudioFloatData *> *waveformDataTask = [self.audioFile getWaveformDataWithNumberOfPointsTask:1024];
  
  __weak typeof(self) weakSelf = self;
  [waveformDataTask continueOnMainThreadWithBlock:^id (BFTask<EZAudioFloatData *> *task) {
    EZAudioFloatData *floatData = task.result;
    if (floatData && weakSelf) {
      [weakSelf.audioPlot updateBuffer:floatData.buffers[0] withBufferSize:floatData.bufferSize];
    } else {
      NSLog(@"WaveformView: Float data is unexpectedly nil!");
    }
    
    return nil;
  }];
  

//  __weak typeof(self) weakSelf = self;
//  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//    // Manually extract waveform data instead of completion block to prevent early memory release
//    EZAudioFloatData *waveformData = [weakSelf.audioFile getWaveformDataWithNumberOfPoints:1024];
//    if (waveformData) {
//      dispatch_async(dispatch_get_main_queue(), ^{
//        // Passing waveformData object here guarantees it stays alive during updateBuffer
//        if (weakSelf && waveformData) {
//          [weakSelf.audioPlot updateBuffer:waveformData.buffers[0] withBufferSize:waveformData.bufferSize];
//        }
//      });
//    }
//  });
}

- (void)setProgress:(double)progress {
  _progress = MAX(0.0, MIN(1.0, progress));
  [self updateNeedlePosition];
}

- (void)updateNeedlePosition {
  CGFloat needleX = self.bounds.size.width * self.progress;
  self.progressOverlayView.frame = NSMakeRect(0, 0, needleX, self.bounds.size.height);
  self.needleView.frame = NSMakeRect(needleX - 1, 0, 2, self.bounds.size.height);
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)event {
  [self updateProgressFromEvent:event];
}

- (void)mouseDragged:(NSEvent *)event {
  [self updateProgressFromEvent:event];
}

- (void)mouseUp:(NSEvent *)event {
  [self updateProgressFromEvent:event];
}

- (void)updateProgressFromEvent:(NSEvent *)event {
  NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
  double progress = location.x / self.bounds.size.width;
  progress = MAX(0.0, MIN(1.0, progress));

  dispatch_async(dispatch_get_main_queue(), ^{
    self.progress = progress;

    if ([self.delegate respondsToSelector:@selector(waveformView:didSeekToProgress:)]) {
      [self.delegate waveformView:self didSeekToProgress:progress];
    }
  });
}

@end

