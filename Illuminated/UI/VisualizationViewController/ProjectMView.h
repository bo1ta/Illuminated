//
//  ProjectMView.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.02.2026.
//

#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>

@interface ProjectMView : NSOpenGLView
- (void)addPCMData:(const float *)monoData length:(AVAudioFrameCount)length;

- (void)playNextPresetWithHardCut:(BOOL)hardCut;
- (void)playPreviousPresetWithHardCut:(BOOL)hardCut;
- (void)playLastPresetWithHardCut:(BOOL)hardCut;
- (void)setShuffleEnabled:(BOOL)enabled;
- (BOOL)isShuffleEnabled;

- (void)cleanup;

@end
