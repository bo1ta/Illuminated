//
//  VisualizationPresetQueue.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Foundation/Foundation.h>

@protocol VisualizationPreset;

NS_ASSUME_NONNULL_BEGIN

/**
 * Manages a circular queue of visualization presets for easy navigation.
 * Supports next/previous navigation with wrapping.
 */
@interface VisualizationPresetQueue : NSObject

/**
 * The currently selected preset
 */
@property(nonatomic, readonly, nullable) id<VisualizationPreset> currentPreset;

/**
 * The current index in the queue
 */
@property(nonatomic, readonly) NSInteger currentIndex;

/**
 * Total number of presets in the queue
 */
@property(nonatomic, readonly) NSUInteger count;

/**
 * All presets in the queue
 */
@property(nonatomic, readonly) NSArray<id<VisualizationPreset>> *allPresets;

/**
 * Initialize with an array of presets
 * @param presets Array of presets to cycle through
 */
- (instancetype)initWithPresets:(NSArray<id<VisualizationPreset>> *)presets NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Initialize with all available presets from the preset manager
 */
+ (instancetype)queueWithAllAvailablePresets;

/**
 * Move to the next preset in the queue (wraps around to beginning)
 * @return The next preset
 */
- (nullable id<VisualizationPreset>)nextPreset;

/**
 * Move to the previous preset in the queue (wraps around to end)
 * @return The previous preset
 */
- (nullable id<VisualizationPreset>)previousPreset;

/**
 * Jump to a specific index
 * @param index The index to jump to
 * @return The preset at that index, or nil if out of bounds
 */
- (nullable id<VisualizationPreset>)presetAtIndex:(NSInteger)index;

/**
 * Jump to a preset by identifier
 * @param identifier The preset identifier
 * @return YES if found and selected, NO otherwise
 */
- (BOOL)selectPresetWithIdentifier:(NSString *)identifier;

/**
 * Reset to the first preset
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
