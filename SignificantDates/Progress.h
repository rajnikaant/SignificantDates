//
//  Progress.h
//  SignificantDates
//
//  Created by Udit Sajjanhar on 15/04/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

@class Account;

@interface Progress : BaseModel

@property (nonatomic, retain) NSNumber * percent;
@property (nonatomic, retain) NSManagedObject *chapter;
@property (nonatomic, retain) NSManagedObject *player;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber *writeId;
@property (nonatomic, retain) Account  *account;

@end
