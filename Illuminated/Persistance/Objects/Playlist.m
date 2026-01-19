//
//  Playlist.m
//  
//
//  Created by Alexandru Solomon on 18.01.2026.
//
//

#import "Playlist.h"

@implementation Playlist

+ (NSFetchRequest<Playlist *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Playlist"];
}

@dynamic uniqueID;
@dynamic name;
@dynamic isSmart;
@dynamic iconName;
@dynamic tracks;

@end
