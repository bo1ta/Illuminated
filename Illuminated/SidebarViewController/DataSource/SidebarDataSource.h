//
//  SidebarDataSource.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SidebarItem;

@interface SidebarDataSource : NSObject

@property (nonatomic, strong, readonly) NSArray<SidebarItem *> *items;

+ (instancetype)sharedDataSource;
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
