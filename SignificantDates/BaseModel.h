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
+ (NSManagedObject*)createWithDictionary:(NSDictionary*)dict inContext:(NSManagedObjectContext*)givenMoc;
+ (void)createWithDictionaries:(NSArray*)dicts inContext:(NSManagedObjectContext*)givenMoc;
@end
