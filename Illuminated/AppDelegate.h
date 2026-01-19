//
//  AppDelegate.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong) NSPersistentContainer *persistentContainer;

@end

