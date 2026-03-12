//
//  WaveformView.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WaveformViewDelegate;

@interface WaveformView : NSView

@property(nonatomic, weak) id<WaveformViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSImage *waveformImage;
@property(nonatomic) double progress;

@end

@protocol WaveformViewDelegate<NSObject>

- (void)waveformView:(WaveformView *)waveformView didSeekToProgress:(double)progress;

@end

NS_ASSUME_NONNULL_END
