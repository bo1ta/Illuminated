//
//  MetadataExtractor.h
//  Illuminated
//
//  Created by Alexandru Solomon on 25.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetadataExtractor : NSObject
+ (NSDictionary *)extractMetadataFromFileAtURL:(NSURL *)fileURL;
@end

NS_ASSUME_NONNULL_END
