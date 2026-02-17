//
//  FileBrowserLocation+CoreDataProperties.m
//  Illuminated
//
//  Created by Alexandru Solomon on 17.02.2026.
//
//

#import "FileBrowserLocation.h"

@implementation FileBrowserLocation

+ (NSFetchRequest<FileBrowserLocation *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"FileBrowserLocation"];
}

@dynamic displayName;
@dynamic dateAdded;
@dynamic bookmarkData;
@dynamic originalPath;
@dynamic isExpanded;
@dynamic displayOrder;

@end
