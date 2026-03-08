//
//  FileExtensionHelper.m
//  Illuminated
//
//  Created by Alexandru Solomon on 07.03.2026.
//

#import "FileExtensionHelper.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@implementation FileExtensionHelper

+ (NSSet<NSString *> *)audioExtensions {
    static NSSet *extensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extensions = [NSSet setWithArray:@[@"mp3", @"m4a", @"wav", @"aiff",
                                           @"flac", @"aac", @"ogg", @"wma"]];
    });
    return extensions;
}

+ (BOOL)isAudioFileExtension:(NSString *)extension {
    return [[self audioExtensions] containsObject:extension.lowercaseString];
}


+ (NSArray<UTType *> *)audioUTTypes {
    static NSArray<UTType *> *types = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        types = @[
            UTTypeAudio,
            UTTypeMP3,
            UTTypeMPEG4Audio,
            [UTType typeWithFilenameExtension:@"wav"],
            [UTType typeWithFilenameExtension:@"aiff"],
            [UTType typeWithFilenameExtension:@"flac"],
            [UTType typeWithFilenameExtension:@"aac"],
            [UTType typeWithFilenameExtension:@"ogg"],
            [UTType typeWithFilenameExtension:@"wma"],
        ];
    });
    return types;
}

@end
