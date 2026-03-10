//
//  PlaybackItem.h
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, PlaybackItemType) {
  PlaybackItemTypeTrack,
  PlaybackItemTypeRadio,
};

NS_ASSUME_NONNULL_BEGIN

@protocol PlaybackItem<NSObject>

@property(nonatomic, readonly) NSString *displayTitle;
@property(nonatomic, readonly) NSString *subtitle;
@property(nonatomic, readonly) NSURL *playbackURL;
@property(nonatomic, readonly) PlaybackItemType type;
@property(nonatomic, readonly, nullable) NSImage *artworkImage;

@end

NS_ASSUME_NONNULL_END
