//
//  CoreErrors.m
//  Illuminated
//
//  Created by Alexandru Solomon on 21.01.2026.
//

#import "CoreErrors.h"
#import <CoreData/CoreDataErrors.h>
#import <Foundation/Foundation.h>

NSString *const CoreErrorDomain = @"com.illuminated.core";

@implementation NSError (CoreErrors)

#pragma mark - Constructor

+ (instancetype)validationError:(NSString *)message {
  return [self errorWithDomain:CoreErrorDomain
                          code:CoreErrorValidation
                      userInfo:@{
                        NSLocalizedDescriptionKey : @"Validation Failed",
                        NSLocalizedFailureReasonErrorKey : message ?: @"Invalid input",
                        NSLocalizedRecoverySuggestionErrorKey : @"Please check your input and try again."
                      }];
}

+ (instancetype)notFoundError:(NSString *)entityName identifier:(nullable id)identifier {
  NSString *description = [NSString stringWithFormat:@"%@ not found", entityName];
  NSString *reason = identifier ? [NSString stringWithFormat:@"No %@ with identifier %@", entityName, identifier]
                                : [NSString stringWithFormat:@"No %@ found", entityName];

  NSMutableDictionary *userInfo = [@{
    NSLocalizedDescriptionKey : description,
    NSLocalizedFailureReasonErrorKey : reason,
  } mutableCopy];

  if (identifier) {
    userInfo[@"identifier"] = identifier;
  }

  return [self errorWithDomain:CoreErrorDomain code:CoreErrorNotFound userInfo:userInfo];
}

+ (instancetype)duplicateError:(NSString *)entityName {
  return
      [self errorWithDomain:CoreErrorDomain
                       code:CoreErrorDuplicate
                   userInfo:@{
                     NSLocalizedDescriptionKey : @"Duplicate Entry",
                     NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@ already exists", entityName],
                     NSLocalizedRecoverySuggestionErrorKey : @"Use a different identifier or update the existing entry."
                   }];
}

+ (instancetype)unauthorizedError:(NSString *)action {
  return [self errorWithDomain:CoreErrorDomain
                          code:CoreErrorUnauthorized
                      userInfo:@{
                        NSLocalizedDescriptionKey : @"Unauthorized",
                        NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"Cannot perform: %@", action],
                        NSLocalizedRecoverySuggestionErrorKey : @"Please check your permissions."
                      }];
}

+ (instancetype)databaseError:(NSString *)operation underlyingError:(nullable NSError *)underlyingError {
  NSMutableDictionary *userInfo = [@{
    NSLocalizedDescriptionKey : @"Database Error",
    NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"Failed to %@", operation],
    NSLocalizedRecoverySuggestionErrorKey : @"Please try again later."
  } mutableCopy];

  if (underlyingError) {
    userInfo[NSUnderlyingErrorKey] = underlyingError;
  }

  return [self errorWithDomain:CoreErrorDomain code:CoreErrorDatabase userInfo:userInfo];
}

+ (instancetype)fileErrorWithPath:(NSString *)path {
  return [self errorWithDomain:CoreErrorDomain
                          code:CoreErrorFileSystem
                      userInfo:@{
                        NSLocalizedDescriptionKey : @"File System Error",
                        NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"Invalid file: %@", path],
                        NSFilePathErrorKey : path ?: @"",
                        NSLocalizedRecoverySuggestionErrorKey : @"Check file permissions and try again."
                      }];
}

#pragma mark - Convenience Methods

- (BOOL)isValidationError {
  return [self.domain isEqualToString:CoreErrorDomain] && self.code == CoreErrorValidation;
}

- (BOOL)isNotFoundError {
  return [self.domain isEqualToString:CoreErrorDomain] && self.code == CoreErrorNotFound;
}

- (BOOL)isDuplicateError {
  return [self.domain isEqualToString:CoreErrorDomain] && self.code == CoreErrorDuplicate;
}

- (NSString *)humanReadableDescription {
  if ([self.domain isEqualToString:CoreErrorDomain]) {
    switch (self.code) {
    case CoreErrorValidation:
      return @"Please check your input.";
    case CoreErrorNotFound:
      return @"The item was not found.";
    case CoreErrorDuplicate:
      return @"This item already exists.";
    case CoreErrorUnauthorized:
      return @"You don't have permission to do that.";
    default:
      return self.localizedDescription ?: @"An error occurred.";
    }
  }

  // Handle NSError from other domains (CoreData, Network, etc.)
  if ([self.domain isEqualToString:NSCocoaErrorDomain]) {
    // Core Data errors
    if (self.code == NSManagedObjectValidationError) {
      return @"Invalid data entered.";
    }
    if (self.code == NSPersistentStoreIncompatibleVersionHashError) {
      return @"Database version mismatch. Please update the app.";
    }
  }

  if ([self.domain isEqualToString:NSURLErrorDomain]) {
    return @"Network connection failed. Please check your internet.";
  }

  return self.localizedDescription ?: @"An unexpected error occurred.";
}

@end
