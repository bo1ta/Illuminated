//
//  Track.m
//
//
//  Created by Alexandru Solomon on 18.01.2026.
//
//

#import "Track.h"

@implementation Track

+ (NSFetchRequest<Track *> *)fetchRequest {
  return [NSFetchRequest fetchRequestWithEntityName:@"Track"];
}

@dynamic uniqueID;
@dynamic title;
@dynamic duration;
@dynamic trackNumber;
@dynamic discNumber;
@dynamic fileURL;
@dynamic fileType;
@dynamic bitrate;
@dynamic sampleRate;
@dynamic playCount;
@dynamic lastPlayed;
@dynamic rating;
@dynamic genre;
@dynamic lyrics;
@dynamic year;
@dynamic album;
@dynamic artist;
@dynamic playlists;
@dynamic urlBookmark;

@end
