//
//  NSDictionary+Merge.h
//  Illuminated
//
//  Created by Alexandru Solomon on 24.01.2026.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Merge)
- (NSDictionary *)dictionaryByMergingWithDictionary:(NSDictionary *)other;
- (NSDictionary *)dictionaryByPreferringExistingOverDictionary:(NSDictionary *)other;
@end

NS_ASSUME_NONNULL_END
