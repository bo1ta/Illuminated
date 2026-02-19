//
//  FileBrowserLocation+CoreDataProperties.h
//  Illuminated
//
//  Created by Alexandru Solomon on 17.02.2026.
//
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileBrowserLocation : NSManagedObject

+ (NSFetchRequest<FileBrowserLocation *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property(nullable, nonatomic, copy) NSString *displayName;
@property(nullable, nonatomic, copy) NSDate *dateAdded;
@property(nullable, nonatomic, retain) NSData *bookmarkData;
@property(nullable, nonatomic, copy) NSString *originalPath;
@property(nonatomic) BOOL isExpanded;
@property(nonatomic) int32_t displayOrder;

@end

NS_ASSUME_NONNULL_END
