//
//  ContentTabViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MusicViewController, VizualizationViewController;

@interface ContentTabViewController : NSViewController

@property(nonatomic, strong) MusicViewController *musicViewController;
@property(nonatomic, strong) VizualizationViewController *vizualizationViewController;

- (void)switchToMusic;
- (void)switchToVizualizer;

@end

NS_ASSUME_NONNULL_END
