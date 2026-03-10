//
//  RadioStation+PlaybackItem.m
//  Illuminated
//
//  Created by Alexandru Solomon on 09.03.2026.
//

#import "ArtworkManager.h"
#import "RadioStation+PlaybackItem.h"

@implementation RadioStation (PlaybackItem)

- (NSString *)displayTitle {
  return self.name;
}

- (NSString *)subtitle {
  return self.country;
}

- (NSURL *)playbackURL {
  return [NSURL URLWithString:self.url];
}

- (PlaybackItemType)type {
  return PlaybackItemTypeRadio;
}

- (NSImage *)artworkImage {
  return [ArtworkManager placeholderImageWithSize:CGSizeMake(45, 45)];
}

@end
