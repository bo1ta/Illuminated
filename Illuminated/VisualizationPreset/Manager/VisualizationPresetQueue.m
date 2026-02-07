//
//  VisualizationPresetQueue.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "VisualizationPresetQueue.h"
#import "VisualizationPreset.h"
#import "VisualizationPresetManager.h"

@interface VisualizationPresetQueue ()

@property(nonatomic, copy) NSArray<id<VisualizationPreset>> *presets;
@property(nonatomic, assign) NSInteger currentIndex;

@end

@implementation VisualizationPresetQueue

#pragma mark - Lifecycle

- (instancetype)initWithPresets:(NSArray<id<VisualizationPreset>> *)presets {
  self = [super init];
  if (self) {
    if (presets.count == 0) {
      NSLog(@"VisualizationPresetQueue: Warning - initialized with empty preset array");
      _presets = @[];
    } else {
      _presets = [presets copy];
    }
    _currentIndex = 0;
  }
  return self;
}

+ (instancetype)queueWithAllAvailablePresets {
  VisualizationPresetManager *manager = [VisualizationPresetManager sharedManager];
  return [[self alloc] initWithPresets:manager.availablePresets];
}

#pragma mark - Properties

- (id<VisualizationPreset>)currentPreset {
  if (_presets.count == 0) {
    return nil;
  }
  return _presets[_currentIndex];
}

- (NSInteger)currentIndex {
  return _currentIndex;
}

- (NSUInteger)count {
  return _presets.count;
}

- (NSArray<id<VisualizationPreset>> *)allPresets {
  return [_presets copy];
}

#pragma mark - Navigation

- (nullable id<VisualizationPreset>)nextPreset {
  if (_presets.count == 0) {
    return nil;
  }

  // Move to next index (wrap around)
  _currentIndex = (_currentIndex + 1) % _presets.count;

  id<VisualizationPreset> preset = _presets[_currentIndex];
  NSLog(@"VisualizationPresetQueue: Next -> %@ (%ld/%lu)",
        preset.displayName,
        (long)_currentIndex + 1,
        (unsigned long)_presets.count);

  return preset;
}

- (nullable id<VisualizationPreset>)previousPreset {
  if (_presets.count == 0) {
    return nil;
  }

  // Move to previous index (wrap around)
  _currentIndex = (_currentIndex - 1 + _presets.count) % _presets.count;

  id<VisualizationPreset> preset = _presets[_currentIndex];
  NSLog(@"VisualizationPresetQueue: Previous -> %@ (%ld/%lu)",
        preset.displayName,
        (long)_currentIndex + 1,
        (unsigned long)_presets.count);

  return preset;
}

- (nullable id<VisualizationPreset>)presetAtIndex:(NSInteger)index {
  if (index < 0 || index >= _presets.count) {
    NSLog(@"VisualizationPresetQueue: Index %ld out of bounds [0, %lu)", (long)index, (unsigned long)_presets.count);
    return nil;
  }

  _currentIndex = index;
  return _presets[_currentIndex];
}

- (BOOL)selectPresetWithIdentifier:(NSString *)identifier {
  for (NSInteger i = 0; i < _presets.count; i++) {
    id<VisualizationPreset> preset = _presets[i];
    if ([preset.identifier isEqualToString:identifier]) {
      _currentIndex = i;
      NSLog(@"VisualizationPresetQueue: Selected '%@' at index %ld", preset.displayName, (long)_currentIndex);
      return YES;
    }
  }

  NSLog(@"VisualizationPresetQueue: Preset with identifier '%@' not found", identifier);
  return NO;
}

- (void)reset {
  _currentIndex = 0;
  NSLog(@"VisualizationPresetQueue: Reset to first preset");
}

@end
