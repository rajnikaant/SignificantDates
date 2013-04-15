//
//  Option.h
//  SignificantDates
//
//  Created by Udit Sajjanhar on 09/04/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Option : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * writeId;

+ (void)createWithKey:(NSString*)key andValue:(NSString*)value;
+ (void)createWithKeys:(NSArray*)key andValues:(NSArray*)values;
+ (Option*)findWithKey:(NSString*)key;
+ (NSArray*)findAllWithKey:(NSString*)key;
@end
