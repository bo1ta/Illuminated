//
//  FileBrowserItem.m
//  Illuminated
//
//  Created by Alexandru Solomon on 07.02.2026.
//

#import "FileBrowserItem.h"

@interface FileBrowserItem ()

@property(nonatomic, strong, readwrite) NSURL *url;
@property(nonatomic, copy, readwrite) NSString *displayName;
@property(nonatomic, copy, readwrite) NSString *typeIdentifier;
@property(nonatomic, assign, readwrite, getter=isDirectory) BOOL directory;
@property(nonatomic, strong, readwrite) NSImage *icon;

@end

@implementation FileBrowserItem

- (instancetype)initWithURL:(NSURL *)url
                displayName:(NSString *)displayName
                  directory:(BOOL)isDirectory
             typeIdentifier:(NSString *)typeIdentifier
                       icon:(NSImage *)icon {
  self = [super init];
  if (self) {
    _url = url;
    _displayName = [displayName copy];
    _directory = isDirectory;
    _typeIdentifier = [typeIdentifier copy];
    _icon = icon;
  }
  return self;
}

@end
