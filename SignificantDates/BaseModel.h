//
//  BaseModel.h
//  SignificantDates
//
//  Created by Udit Sajjanhar on 15/04/13.
//
//

#import <CoreData/CoreData.h>

@interface BaseModel : NSManagedObject

+ (NSString*)entityName;

//create
+ (NSManagedObject*)createWithDictionary:(NSDictionary*)dict inContext:(NSManagedObjectContext*)givenMoc;
+ (void)createWithDictionaries:(NSArray*)dicts inContext:(NSManagedObjectContext*)givenMoc;

//find
+ (NSArray*)findAllWithPredicate:(NSPredicate*)predicate sortDescriptors:(NSMutableArray*)sortDescriptors limit:(int)limit  inContext:(NSManagedObjectContext*)givenMoc;
+ (NSManagedObject*)findFirstWithPredicate:(NSPredicate*)predicate sortDescriptors:(NSMutableArray*)sortDescriptors  inContext:(NSManagedObjectContext*)givenMoc;

@end
