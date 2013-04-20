//
//  Player.h
//  SignificantDates
//
//  Created by Udit Sajjanhar on 15/04/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

@class Progress, Account;

@interface Player : BaseModel

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Progress *progress;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber *writeId;
@property (nonatomic, retain) Account *account;

@end
