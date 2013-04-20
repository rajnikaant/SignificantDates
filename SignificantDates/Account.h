//
//  Account.h
//  SignificantDates
//
//  Created by Udit Sajjanhar on 18/04/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

@class Option, Player, Progress;

@interface Account : BaseModel

@property (nonatomic, retain) NSString * authToken;
@property (nonatomic, retain) NSString * clientId;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * gspid;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * writeId;

@property (nonatomic, retain) NSSet *options;
@property (nonatomic, retain) NSSet *players;
@property (nonatomic, retain) NSSet *progress;

+(void)createWithParams:(NSDictionary*)params;

@end

