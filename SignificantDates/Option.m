//
//  Options.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 09/04/13.
//
//

#import "Option.h"
#import "SDCoreDataController.h"

@implementation Option

@dynamic key;
@dynamic value;
@dynamic updatedAt;
@dynamic writeId;
@dynamic account;


+(NSString*)entityName {
    return @"Option";
}

+(BOOL) isAccountEntity {
    return YES;
}

+ (void)createWithKey:(NSString*)key andValue:(NSString*)value {
    NSMutableDictionary *option = [NSMutableDictionary dictionary];
    [option setValue:key forKey:@"key"];
    [option setValue:value forKey:@"value"];
    
    [self createWithDictionary:option inContext:NULL];
}

+ (void)createWithKeys:(NSArray*)keys andValues:(NSArray*)values {
    NSMutableArray *dicts = [NSMutableArray array];
    
    for (NSString *key in keys) {
        //get the value corresponding to the key
        int index = [keys indexOfObject:key];
        NSString *value = [values objectAtIndex:index];
        
        //make the option in managed context
        NSMutableDictionary *option = [NSMutableDictionary dictionary];
        [option setValue:key forKey:@"key"];
        [option setValue:value forKey:@"value"];
        
        [dicts addObject:option];
    }

    [self createWithDictionaries:dicts inContext:NULL];
}

+ (Option*)findWithKey:(NSString*)key {
    return [[self findAllWithKey:key] lastObject];
}

+ (NSArray*)findAllWithKey:(NSString*)key {
    __block NSArray *results = nil;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"key = %@", key];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    [request setPredicate:pred];
    [request setSortDescriptors:[NSArray arrayWithObject:
                                 [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]]];
    [request setFetchLimit:1];
    
    [[[SDCoreDataController sharedInstance] backgroundManagedObjectContext] performBlockAndWait:^{
        NSError *error = nil;
        results = [[[SDCoreDataController sharedInstance] backgroundManagedObjectContext] executeFetchRequest:request error:&error];
    }];
    
    return results;
}

+ (void)setValue:(id)value forKey:(NSString*)key {
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"key = %@", key];
    Option *opt = (Option*)[self findFirstWithPredicate:pred
                                        sortDescriptors:nil
                                              inContext:moc];
    if (opt) {
        [opt setValue:value forKey:@"value"];
        [moc performBlockAndWait:^{
            NSError *error = nil;
            BOOL saved = [moc save:&error];
            if (!saved) {
                // do some real error handling
                NSLog(@"Could not save Date due to %@", error);
            }
            [[SDCoreDataController sharedInstance] saveMasterContext];
        }];
    } else {
        [[self class] createWithKey:key andValue:value];
    }
}
@end
