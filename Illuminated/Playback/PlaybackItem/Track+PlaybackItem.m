//
//  Track+PlaybackItem.m
//  Illuminated
//
//  Created by Alexandru Solomon on 08.03.2026.
//

#import "Album.h"
#import "Artist.h"
#import "ArtworkManager.h"
#import "Track+PlaybackItem.h"
#import "TrackService.h"

@implementation Track (PlaybackItem)

- (NSString *)displayTitle {
  return self.title;
}

- (NSString *)subtitle {
  return self.artist.name;
}

- (NSURL *)playbackURL {
  return [NSURL fileURLWithPath:self.fileURL];
}

- (PlaybackItemType)type {
  return PlaybackItemTypeTrack;
}

- (NSImage *)artworkImage {
  if (self.album.artworkPath) {
    return [ArtworkManager loadArtworkAtPath:self.album.artworkPath];
  } else {
    return [ArtworkManager placeholderImageWithSize:CGSizeMake(45, 45)];
  }
}

@end
