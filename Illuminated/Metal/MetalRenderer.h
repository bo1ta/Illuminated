//
//  MetalRenderer.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "VisualizationPreset.h"
#import <MetalKit/MetalKit.h>

@class AudioProcessor;

NS_ASSUME_NONNULL_BEGIN

@interface MetalRenderer : NSObject<MTKViewDelegate>

/**
 * The current visualization preset
 */
@property(nonatomic, strong) id<VisualizationPreset> currentPreset;

/**
 * The audio processor providing data for visualization
 */
@property(nonatomic, strong, readonly) AudioProcessor *audioProcessor;

/**
 * Initializes the renderer with a MetalKit view
 * @param mtkView The MTKView to render into
 */
- (nullable instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

/**
 * Initializes the renderer with a MetalKit view and custom audio buffer size
 * @param mtkView The MTKView to render into
 * @param bufferSize Number of audio samples to visualize (typically 512, 1024, or 2048)
 */
- (nullable instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
                              audioBufferSize:(NSUInteger)bufferSize NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * The audio processor providing data for visualization
 */
- (BOOL)switchToPreset:(id<VisualizationPreset>)preset;

@end

NS_ASSUME_NONNULL_END
