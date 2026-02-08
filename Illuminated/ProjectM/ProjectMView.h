//
//  ProjectMView.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>
#import <projectM-4/playlist.h>
#import <projectM-4/playlist_items.h>
#import <projectM-4/playlist_playback.h>
#import <projectM-4/projectM.h>

@interface ProjectMHandler : NSOpenGLView

- (void)renderFrame;

- (void)addPCMData:(const float *)monoData length:(AVAudioFrameCount)length;

- (void)loadPresetsFromDirectory:(NSString *)directoryPath recurseSubdirs:(BOOL)recurse allowDuplicates:(BOOL)allow;
- (void)playRandomPresetWithHardCut:(BOOL)hardCut;
- (void)playNextPresetWithHardCut:(BOOL)hardCut;
- (void)playPreviousPresetWithHardCut:(BOOL)hardCut;
- (void)playLastPresetWithHardCut:(BOOL)hardCut;
- (void)setShuffleEnabled:(BOOL)enabled;
- (BOOL)isShuffleEnabled;
- (void)setRetryCount:(uint32_t)count;
- (uint32_t)retryCount;

@end
