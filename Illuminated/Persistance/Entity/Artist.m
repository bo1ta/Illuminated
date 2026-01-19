//
//  Artist.m
//  
//
//  Created by Alexandru Solomon on 18.01.2026.
//
//

#import "Artist.h"

@implementation Artist

+ (NSFetchRequest<Artist *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Artist"];
}

@dynamic uniqueID;
@dynamic name;
@dynamic albums;
@dynamic tracks;

@end
