//
//  VisualizationPresetManager.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Foundation/Foundation.h>

@protocol VisualizationPreset;

NS_ASSUME_NONNULL_BEGIN

/**
 * Manages the collection of available visualization presets.
 * Singleton that provides easy access to all registered presets.
 */
@interface VisualizationPresetManager : NSObject

/**
 * Shared singleton instance
 */
@property(class, nonatomic, readonly) VisualizationPresetManager *sharedManager;

/**
 * Array of all available presets
 */
@property(nonatomic, readonly) NSArray<id<VisualizationPreset>> *availablePresets;

/**
 * Get a preset by its identifier
 * @param identifier The preset identifier
 * @return The preset, or nil if not found
 */
- (nullable id<VisualizationPreset>)presetWithIdentifier:(NSString *)identifier;

/**
 * Get a preset by index
 * @param index The index in the availablePresets array
 * @return The preset, or nil if index is out of bounds
 */
- (nullable id<VisualizationPreset>)presetAtIndex:(NSUInteger)index;

/**
 * Register a custom preset
 * @param preset The preset to register
 */
- (void)registerPreset:(id<VisualizationPreset>)preset;

/**
 * Unregister a preset by identifier
 * @param identifier The identifier of the preset to remove
 */
- (void)unregisterPresetWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
