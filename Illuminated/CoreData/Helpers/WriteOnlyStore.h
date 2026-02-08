//
//  WriteOnlyStore.h
//  Illuminated
//
//  Created by Alexandru Solomon on 18.01.2026.
//

#import "BFTask.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef id _Nullable (^WriteBlock)(NSManagedObjectContext *context);

@protocol WriteOnlyStore<NSObject>

- (BFTask *)performWrite:(WriteBlock)writeBlock;

- (BFTask *)deleteObjectWithEntityName:(NSString *)entityName uniqueID:(NSUUID *)uniqueID;

@end

NS_ASSUME_NONNULL_END
