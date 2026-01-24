//
//  TrackQueue.m
//  Illuminated
//
//  Created by Alexandru Solomon on 23.01.2026.
//

#import "TrackQueue.h"
#import "Track.h"
#import <Foundation/Foundation.h>

@interface TrackQueue ()

@property(strong, nonatomic) NSArray<Track *> *tracks;
@property(readwrite, nonatomic) Track *currentTrack;

@end

@implementation TrackQueue

- (void)setTracks:(NSArray<Track *> *)tracks {
  _tracks = tracks ?: @[];
}

- (void)setCurrentTrack:(Track *)track {
  _currentTrack = track;
}

- (Track *)nextTrack {
  if (self.tracks.count == 0) {
    return nil;
  }

  NSUInteger currentIndex = [self currentTrackIndex];

  if (currentIndex == NSNotFound) {
    return self.tracks.firstObject;
  }

  if (currentIndex < self.tracks.count - 1) {
    return self.tracks[currentIndex + 1];
  }

  return nil;
}

- (Track *)previousTrack {
  if (self.tracks.count == 0 || !self.currentTrack) {
    return nil;
  }

  NSUInteger currentIndex = [self currentTrackIndex];

  if (currentIndex != NSNotFound && currentIndex > 0) {
    return self.tracks[currentIndex - 1];
  }

  return nil;
}

- (BOOL)hasNext {
  NSUInteger currentIndex = [self currentTrackIndex];
  return currentIndex != NSNotFound && currentIndex < self.tracks.count - 1;
}

- (BOOL)hasPrevious {
  NSUInteger currentIndex = [self currentTrackIndex];
  return currentIndex != NSNotFound && currentIndex > 0;
}

#pragma mark - Private

- (NSUInteger)currentTrackIndex {
  if (!self.currentTrack) {
    return NSNotFound;
  }
  return [self.tracks indexOfObject:self.currentTrack];
}

@end
