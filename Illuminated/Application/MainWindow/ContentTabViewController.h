//
//  ContentTabViewController.h
//  Illuminated
//
//  Created by Alexandru Solomon on 31.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MusicViewController, VizualizationViewController, RadioViewController;

@interface ContentTabViewController : NSViewController

@property(nonatomic, strong) MusicViewController *musicViewController;
@property(nonatomic, strong) RadioViewController *radioViewController;
@property(nonatomic, nullable, strong) VizualizationViewController *vizualizationViewController;

- (void)switchToMusic;
- (void)switchToRadio;
- (void)switchToVizualizer;

- (void)searchQuery:(NSString *)query;

@end

NS_ASSUME_NONNULL_END
