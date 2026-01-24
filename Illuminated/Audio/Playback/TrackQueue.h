//
//  TrackQueue.h
//  Illuminated
//
//  Created by Alexandru Solomon on 23.01.2026.
//

#import "Cocoa/Cocoa.h"

NS_ASSUME_NONNULL_BEGIN

@class Track;

@interface TrackQueue : NSObject

@property(readonly, nonatomic) Track *currentTrack;
@property(readonly, nonatomic) NSArray<Track *> *tracks;

- (void)setTracks:(NSArray<Track *> *)tracks;
- (void)setCurrentTrack:(Track *)track;

- (Track *)nextTrack;
- (Track *)previousTrack;

- (BOOL)hasNext;
- (BOOL)hasPrevious;

@end

NS_ASSUME_NONNULL_END
