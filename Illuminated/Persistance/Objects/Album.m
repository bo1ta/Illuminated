//
//  Album.m
//  
//
//  Created by Alexandru Solomon on 18.01.2026.
//
//

#import "Album.h"

@implementation Album

+ (NSFetchRequest<Album *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Album"];
}

@dynamic uniqueID;
@dynamic title;
@dynamic year;
@dynamic artworkPath;
@dynamic duration;
@dynamic genre;
@dynamic tracks;
@dynamic artist;

@end
