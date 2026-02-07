//
//  VisualizationPreset.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VisualizationPreset<NSObject>

/**
 * Unique identifier for this preset
 */
@property(nonatomic, readonly) NSString *identifier;

/**
 * Display name for this preset
 */
@property(nonatomic, readonly) NSString *displayName;

/**
 * Name of the vertex shader function in the Metal library
 */
@property(nonatomic, readonly) NSString *vertexFunctionName;

/**
 * Name of the fragment shader function in the Metal library
 */
@property(nonatomic, readonly) NSString *fragmentFunctionName;

/**
 * The primitive type to use for rendering (e.g., triangle strip, points, lines)
 */
@property(nonatomic, readonly) MTLPrimitiveType primitiveType;

/**
 * Whether this preset requires blending to be enabled
 */
@property(nonatomic, readonly) BOOL requiresBlending;

@optional

/**
 * Custom blend configuration. Override to provide specific blend modes.
 * If not implemented, default additive blending will be used.
 */
- (void)configureBlending:(MTLRenderPipelineColorAttachmentDescriptor *)attachment;

/**
 * Custom vertex count calculation based on audio buffer size.
 * Default is to use the audio buffer size directly.
 */
- (NSUInteger)vertexCountForAudioBufferSize:(NSUInteger)bufferSize;

/**
 * Additional setup before drawing (e.g., setting custom uniforms).
 * Called once per frame before encoding draw commands.
 */
- (void)prepareForDrawingWithEncoder:(id<MTLRenderCommandEncoder>)encoder time:(float)time amplitude:(float)amplitude;

/**
 * Array of texture filenames (without extension) to load for this preset.
 * Return nil or empty array if no textures needed.
 * Textures should be in the app bundle's Resources folder.
 * Supported formats: PNG, JPG, KTX, PVR
 */
- (nullable NSArray<NSString *> *)textureNames;

/**
 * Called after textures are loaded. Store references if needed.
 * Textures are bound to indices 0, 1, 2, etc. in order of textureNames array.
 * @param textures Array of MTLTexture objects corresponding to textureNames
 */
- (void)texturesDidLoad:(NSArray<id<MTLTexture>> *)textures;

@end

NS_ASSUME_NONNULL_END
