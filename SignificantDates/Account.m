//
//  Account.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 18/04/13.
//
//

#import "Account.h"
#import "Option.h"
#import "Player.h"
#import "Progress.h"


@implementation Account

@dynamic authToken;
@dynamic clientId;
@dynamic email;
@dynamic gspid;
@dynamic updatedAt;
@dynamic writeId;

@dynamic options;
@dynamic players;
@dynamic progress;


+(NSString*)entityName {
    return @"Account";
}

+ (void)createWithParams:(NSDictionary*)params {
    NSDictionary *account = [NSMutableDictionary dictionary];
    [account setValue:[params valueForKey:@"gspid"] forKey:@"gspid"];
    [account setValue:[[params valueForKey:@"client_id"] stringValue] forKey:@"clientId"];
    [account setValue:[params valueForKey:@"auth_token"] forKey:@"authToken"];
    [account setValue:[params valueForKey:@"email"] forKey:@"email"];
    [self createWithDictionary:account inContext:nil];
}

@end
