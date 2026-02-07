//
//  VisualizationPresetManager.m
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import "VisualizationPresetManager.h"
#import "AlienCorePreset.h"
#import "CircularWavePreset.h"
#import "CosmicVoidPreset.h"
#import "IndustrialGhost.h"
#import "NeuralPulsePreset.h"
#import "SineVoronoiPreset.h"
#import "SpaceCentipedePreset.h"
#import "TriangleFractalPreset.h"
#import "VisualizationPreset.h"

@interface VisualizationPresetManager ()

@property(nonatomic, strong) NSMutableArray<id<VisualizationPreset>> *presets;
@property(nonatomic, strong) NSMutableDictionary<NSString *, id<VisualizationPreset>> *presetsByIdentifier;

@end

@implementation VisualizationPresetManager

#pragma mark - Singleton

+ (VisualizationPresetManager *)sharedManager {
  static VisualizationPresetManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ sharedInstance = [[self alloc] init]; });
  return sharedInstance;
}

#pragma mark - Lifecycle

- (instancetype)init {
  self = [super init];
  if (self) {
    _presets = [NSMutableArray array];
    _presetsByIdentifier = [NSMutableDictionary dictionary];

    [self registerBuiltInPresets];
  }
  return self;
}

- (void)registerBuiltInPresets {
  [self registerPreset:[[CircularWavePreset alloc] init]];
  [self registerPreset:[[IndustrialGhost alloc] init]];
  [self registerPreset:[[NeuralPulsePreset alloc] init]];
  [self registerPreset:[[TriangleFractalPreset alloc] init]];
  [self registerPreset:[[SineVoronoiPreset alloc] init]];
  [self registerPreset:[[AlienCorePreset alloc] init]];
  [self registerPreset:[[CosmicVoidPreset alloc] init]];
  [self registerPreset:[[SpaceCentipedePreset alloc] init]];
}

#pragma mark - Properties

- (NSArray<id<VisualizationPreset>> *)availablePresets {
  return [_presets copy];
}

#pragma mark - Public Methods

- (nullable id<VisualizationPreset>)presetWithIdentifier:(NSString *)identifier {
  return _presetsByIdentifier[identifier];
}

- (nullable id<VisualizationPreset>)presetAtIndex:(NSUInteger)index {
  if (index >= _presets.count) {
    return nil;
  }
  return _presets[index];
}

- (void)registerPreset:(id<VisualizationPreset>)preset {
  if (!preset) {
    NSLog(@"VisualizationPresetManager: Cannot register nil preset");
    return;
  }

  NSString *identifier = preset.identifier;
  if (!identifier || identifier.length == 0) {
    NSLog(@"VisualizationPresetManager: Cannot register preset with empty identifier");
    return;
  }

  if (_presetsByIdentifier[identifier]) {
    NSLog(@"VisualizationPresetManager: Preset with identifier '%@' already registered, replacing", identifier);
    [self unregisterPresetWithIdentifier:identifier];
  }

  [_presets addObject:preset];
  _presetsByIdentifier[identifier] = preset;

  NSLog(@"VisualizationPresetManager: Registered preset '%@' (%@)", preset.displayName, identifier);
}

- (void)unregisterPresetWithIdentifier:(NSString *)identifier {
  id<VisualizationPreset> preset = _presetsByIdentifier[identifier];
  if (preset) {
    [_presets removeObject:preset];
    [_presetsByIdentifier removeObjectForKey:identifier];
    NSLog(@"VisualizationPresetManager: Unregistered preset '%@'", identifier);
  }
}

@end
