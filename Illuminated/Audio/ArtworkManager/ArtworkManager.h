//
//  ArtworkManager.h
//  Illuminated
//
//  Created by Alexandru Solomon on 25.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArtworkManager : NSObject

+ (NSString *)saveArtwork:(NSData *)artworkData forUUID:(NSUUID *)uuid;

+ (NSImage *)loadArtworkAtPath:(NSString *)path;

+ (void)deleteArtworkAtPath:(NSString *)path;

+ (NSImage *)placeholderImageWithSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
