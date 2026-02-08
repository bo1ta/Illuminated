//
//  WaveformView.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import "WaveformView.h"

@implementation WaveformView {
  NSTrackingArea *_trackingArea;
}

- (void)setWaveformImage:(NSImage *)waveformImage {
  _waveformImage = waveformImage;
  [self setNeedsDisplay:YES];
}

- (void)setProgress:(double)progress {
  _progress = MAX(0.0, MIN(1.0, progress));
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  // Background
  [[NSColor.blackColor colorWithAlphaComponent:0.2] setFill];
  NSRectFill(self.bounds);

  if (self.waveformImage) {
    [self.waveformImage drawInRect:self.bounds
                          fromRect:NSZeroRect
                         operation:NSCompositingOperationSourceOver
                          fraction:1.0];
  }

  // Progress Overlay
  CGFloat needleX = self.bounds.size.width * self.progress;
  NSRect progressRect = NSMakeRect(0, 0, needleX, self.bounds.size.height);

  [[NSColor.systemBlueColor colorWithAlphaComponent:0.3] setFill];
  NSRectFillUsingOperation(progressRect, NSCompositingOperationSourceAtop);

  // Needle
  NSRect needleRect = NSMakeRect(needleX - 1, 0, 2, self.bounds.size.height);
  [NSColor.whiteColor setFill];
  NSRectFill(needleRect);
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

  self.progress = progress;

  if ([self.delegate respondsToSelector:@selector(waveformView:didSeekToProgress:)]) {
    [self.delegate waveformView:self didSeekToProgress:progress];
  }
}

@end
