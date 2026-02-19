//
//  FileBrowserItem.h
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileBrowserItem : NSObject

@property(nonatomic, strong, readonly) NSURL *url;
@property(nonatomic, copy, readonly) NSString *displayName;
@property(nonatomic, copy, readonly, nullable) NSString *typeIdentifier;
@property(nonatomic, assign, readonly, getter=isDirectory) BOOL directory;
@property(nonatomic, strong, readonly) NSImage *icon;
@property(nonatomic, strong, readonly, nullable) NSData *bookmarkData;

- (instancetype)initWithURL:(NSURL *)url
                displayName:(NSString *)displayName
                  directory:(BOOL)isDirectory
             typeIdentifier:(nullable NSString *)typeIdentifier
                       icon:(NSImage *)icon
               bookmarkData:(nullable NSData *)bookmarkData NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
