//
//  FileExtensionHelper.h
//  Illuminated
//
//  Created by Alexandru Solomon on 07.03.2026.
//

#import <Cocoa/Cocoa.h>

@class UTType;

NS_ASSUME_NONNULL_BEGIN

@interface FileExtensionHelper : NSObject

+ (NSSet<NSString *> *)audioExtensions;
+ (BOOL)isAudioFileExtension:(NSString *)extension;

+ (NSArray<UTType *> *)audioUTTypes;

@end

NS_ASSUME_NONNULL_END
