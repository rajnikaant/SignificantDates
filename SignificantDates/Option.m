//
//  Options.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 09/04/13.
//
//

#import "Option.h"
#import "SDCoreDataController.h"

static NSString *entityName = @"Option";

@implementation Option

@dynamic key;
@dynamic value;
@dynamic updatedAt;
@dynamic writeId;

+ (void)createWithKey:(NSString*)key andValue:(NSString*)value {
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    NSManagedObject *option = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                            inManagedObjectContext:moc];
    [option setValue:key forKey:@"key"];
    [option setValue:value forKey:@"value"];
    [option setValue:[[SDCoreDataController sharedInstance] writeId] forKey:@"writeId"];
    [option setValue:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"updatedAt"];
    
    
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

+ (void)createWithKeys:(NSArray*)keys andValues:(NSArray*)values {
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    
    for (NSString *key in keys) {
        //get the value corresponding to the key
        int index = [keys indexOfObject:key];
        NSString *value = [values objectAtIndex:index];
        
        //make the option in managed context
        NSManagedObject *option = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                inManagedObjectContext:moc];
        [option setValue:key forKey:@"key"];
        [option setValue:value forKey:@"value"];
        [option setValue:[[SDCoreDataController sharedInstance] writeId] forKey:@"writeId"];
        [option setValue:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"updatedAt"];
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

+ (Option*)findWithKey:(NSString*)key {
    return [[self findAllWithKey:key] lastObject];
}

+ (NSArray*)findAllWithKey:(NSString*)key {
    __block NSArray *results = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [request setSortDescriptors:[NSArray arrayWithObject:
                                 [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]]];
    [request setFetchLimit:1];
    [[[SDCoreDataController sharedInstance] backgroundManagedObjectContext] performBlockAndWait:^{
        NSError *error = nil;
        results = [[[SDCoreDataController sharedInstance] backgroundManagedObjectContext] executeFetchRequest:request error:&error];
    }];
    
    return results;
}

@end
