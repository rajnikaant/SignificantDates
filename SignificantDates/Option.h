//
//  Option.h
//  SignificantDates
//
//  Created by Udit Sajjanhar on 09/04/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

@class Account;

@interface Option : BaseModel

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * writeId;
@property (nonatomic, retain) Account * account;

+ (void)createWithKey:(NSString*)key andValue:(NSString*)value;
+ (void)createWithKeys:(NSArray*)key andValues:(NSArray*)values;
+ (Option*)findWithKey:(NSString*)key;
+ (NSArray*)findAllWithKey:(NSString*)key;
+ (void)setValue:(id)value forKey:(NSString*)key;
@end
