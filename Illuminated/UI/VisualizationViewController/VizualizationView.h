//
//  VizualizationView.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

@protocol VisualizationPreset;

NS_ASSUME_NONNULL_BEGIN

/**
 * Custom view that handles Metal-based audio visualization
 */
@interface VizualizationView : NSView

/**
 * The current visualization preset
 */
@property(nonatomic, readonly, nullable) id<VisualizationPreset> currentPreset;

/**
 * Update with new audio data
 * @param data Pointer to audio samples
 * @param length Number of samples
 */
- (void)updateAudioData:(const float *)data length:(NSUInteger)length;

/**
 * Start the Metal rendering loop
 */
- (void)startRendering;

/**
 * Stop the Metal rendering loop
 */
- (void)stopRendering;

/**
 * Switch to next preset in the queue
 * @return The new preset, or nil if queue is empty
 */
- (nullable id<VisualizationPreset>)nextPreset;

/**
 * Switch to previous preset in the queue
 * @return The new preset, or nil if queue is empty
 */
- (nullable id<VisualizationPreset>)previousPreset;

/**
 * Switch to a specific preset
 * @param preset The preset to switch to
 * @return YES if successful, NO otherwise
 */
- (BOOL)switchToPreset:(id<VisualizationPreset>)preset;

@end

NS_ASSUME_NONNULL_END
