//
//  SidebarItem.h
//  Illuminated
//
//  Created by Alexandru Solomon on 20.01.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SidebarItemType) {
    SidebarItemTypeGroup,
    SidebarItemTypeItem
};

@interface SidebarItem : NSObject

@property (nonatomic, assign) SidebarItemType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *iconName;
@property (nonatomic, copy, nullable) NSArray<SidebarItem *> *children;

- (instancetype)initWithType:(SidebarItemType)type
                       title:(NSString *)title
                    iconName:(nullable NSString *)iconName
                    children:(nullable NSArray<SidebarItem *> *)children;

+ (instancetype)groupWithTitle:(NSString *)title children:(NSArray<SidebarItem *> *)children;
+ (instancetype)itemWithTitle:(NSString *)title iconName:(nullable NSString *)iconName;

@end

NS_ASSUME_NONNULL_END
