//
//  Player.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 15/04/13.
//
//

#import "Player.h"
#import "Progress.h"


@implementation Player

@dynamic name;
@dynamic progress;
@dynamic updatedAt;
@dynamic writeId;


+(NSString*)entityName {
    return @"Player";
}

@end
