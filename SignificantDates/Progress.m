//
//  Progress.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 15/04/13.
//
//

#import "Progress.h"


@implementation Progress

@dynamic percent;
@dynamic chapter;
@dynamic player;
@dynamic updatedAt;
@dynamic writeId;
@dynamic account;

+(NSString*)entityName {
    return @"Progress";
}

+(BOOL) isAccountEntity {
    return YES;
}

@end
