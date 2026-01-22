//
//  CoreErrors.h
//  Illuminated
//
//  Created by Alexandru Solomon on 21.01.2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const CoreErrorDomain;

typedef NS_ERROR_ENUM(CoreErrorDomain, CoreErrorCode){
    CoreErrorUnknown = -1,          CoreErrorValidation = -100, CoreErrorNotFound = -404,  CoreErrorDuplicate = -409,
    CoreErrorUnauthorized = -401,   CoreErrorNetwork = -1000,   CoreErrorDatabase = -2000, CoreErrorFileSystem = -3000,
    CoreErrorSerialization = -4000, CoreErrorDecoding = -5000};

@interface NSError (CoreErrors)

#pragma mark - Constructors

+ (instancetype)validationError:(NSString *)message;
+ (instancetype)notFoundError:(NSString *)entityName identifier:(nullable id)identifier;
+ (instancetype)duplicateError:(NSString *)entityName;
+ (instancetype)unauthorizedError:(NSString *)action;
+ (instancetype)databaseError:(NSString *)operation underlyingError:(nullable NSError *)underlyingError;
+ (instancetype)fileErrorWithPath:(NSString *)path;

#pragma mark - Utils

- (BOOL)isValidationError;
- (BOOL)isNotFoundError;
- (BOOL)isDuplicateError;
- (NSString *)humanReadableDescription;

@end

NS_ASSUME_NONNULL_END
