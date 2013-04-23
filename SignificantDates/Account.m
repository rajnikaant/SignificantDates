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
#import "SDCoreDataController.h"
#import "Chapter.h"
#import "Constants.h"


@implementation Account

@dynamic authToken;
@dynamic clientId;
@dynamic email;
@dynamic gspid;
@dynamic updatedAt;
@dynamic writeId;
@dynamic isActive;

@dynamic options;
@dynamic players;
@dynamic progress;


+(NSString*)entityName {
    return @"Account";
}

-(void)setSeedDatainContext:(NSManagedObjectContext*)moc {
    //add dataSent key for this account
    NSMutableDictionary *option = [NSMutableDictionary dictionary];
    [option setValue:DBDataSentKey forKey:@"key"];
    [option setValue:@"1" forKey:@"value"];
    [option setValue:self forKey:@"account"];
    [Option createWithDictionary:option inContext:moc];
    
    //add default progress
    NSArray *chapters = [Chapter findAllWithPredicate:nil
                                      sortDescriptors:nil
                                                limit:-1
                                            inContext:moc];
    for (int i = 1; i < 9; i++) {
        NSNumber *number = [NSNumber numberWithInt:i*10];
        NSDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:self forKey:@"account"];
        [dict setValue:[chapters objectAtIndex:(i-1)] forKey:@"chapter"];
        [dict setValue:number forKey:@"percent"];
        [Progress createWithDictionary:dict inContext:moc];
    }
}

+ (Account*)createWithParams:(NSDictionary*)params {
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    
    //build account params
    NSDictionary *account = [NSMutableDictionary dictionary];
    [account setValue:[params valueForKey:@"gspid"] forKey:@"gspid"];
    [account setValue:[[params valueForKey:@"client_id"] stringValue] forKey:@"clientId"];
    [account setValue:[params valueForKey:@"auth_token"] forKey:@"authToken"];
    [account setValue:[params valueForKey:@"email"] forKey:@"email"];
    [account setValue:[NSNumber numberWithInt:0] forKey:@"isActive"];
    
    //save to DB
    Account *newAccount =  (Account*)[self createWithDictionary:account inContext:moc];
    
    //set seed data
    [newAccount setSeedDatainContext:moc];
    
    return newAccount;
}

+(Account*)findActiveInContext:(NSManagedObjectContext *)moc {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isActive = 1"];
    return (Account*)[Account findFirstWithPredicate:pred
                                    sortDescriptors:nil
                                          inContext:moc];
}

+(void)deactivateCurrentInContext:(NSManagedObjectContext*)moc {
    Account *activeAccount = [self findActiveInContext:moc];
    
    if (activeAccount) {
        [activeAccount setIsActive:[NSNumber numberWithInt:0]];
    }
    
    [moc performBlockAndWait:^{
        NSError *error = nil;
        BOOL saved = [moc save:&error];
        if (!saved) {
            // do some real error handling
            NSLog(@"Could not save Date due to %@", error);
        }
        [[SDCoreDataController sharedInstance] saveMasterContext];
    }];
}

-(void)setActiveInContext:(NSManagedObjectContext*)moc {
    self.isActive = [NSNumber numberWithInt:1];
    [moc performBlockAndWait:^{
        NSError *error = nil;
        BOOL saved = [moc save:&error];
        if (!saved) {
            // do some real error handling
            NSLog(@"Could not save Date due to %@", error);
        }
        [[SDCoreDataController sharedInstance] saveMasterContext];
    }];
}

@end
