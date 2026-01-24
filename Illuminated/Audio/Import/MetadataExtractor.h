//
//  MetadataExtractor.h
//  Illuminated
//
//  Created by Alexandru Solomon on 24.01.2026.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetadataExtractor : NSObject
- (NSDictionary *)extractFromItems:(NSArray<AVMetadataItem *> *)items;
- (NSDictionary *)extractAudioFormatFromAudioTrack:(AVAssetTrack *)audioTrack;
- (NSDictionary *)applyFilenameFallback:(NSDictionary *)metadata audioURL:(NSURL *)audioURL;
@end

NS_ASSUME_NONNULL_END
