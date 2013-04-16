 //
//  BaseModel.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 15/04/13.
//
//

#import "BaseModel.h"
#import "SDCoreDataController.h"
#import "Option.h"
#import "Constants.h"

@implementation BaseModel

#pragma mark - Private Methods

+(NSManagedObject*)setParamsForWrite:(NSManagedObject*)mo {
    [mo setValue:[[SDCoreDataController sharedInstance] writeId] forKey:@"writeId"];
    [mo setValue:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"updatedAt"];
    return mo;
}

#pragma mark - Public Methods

+(NSString*) entityName {
    return NULL;
}

+ (NSManagedObject*)createWithDictionary:(NSDictionary*)dict inContext:(NSManagedObjectContext*)givenMoc {
    NSManagedObjectContext *moc = givenMoc;
    if (!moc) {
        moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    }
    
    NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                                            inManagedObjectContext:moc];
    
    for (NSString *key in [dict allKeys]) {
        id value = [dict valueForKey:key];
        [mo setValue:value forKey:key];
    }
    mo = [self setParamsForWrite:mo];

    [moc performBlockAndWait:^{
        NSError *error = nil;
        BOOL saved = [moc save:&error];
        if (!saved) {
            // do some real error handling
            NSLog(@"Could not save Date due to %@", error);
        }
        [[SDCoreDataController sharedInstance] saveMasterContext];
    }];
    
    return mo;
}

+ (void)createWithDictionaries:(NSArray *)dicts inContext:(NSManagedObjectContext*)givenMoc {
    NSManagedObjectContext *moc = givenMoc;
    if (!moc) {
        moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    }
    
    for (NSDictionary *dict in dicts) {
        NSManagedObject *mo = [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                                            inManagedObjectContext:moc];
        for (NSString *key in [dict allKeys]) {
            id value = [dict valueForKey:key];
            [mo setValue:value forKey:key];
        }
        mo = [self setParamsForWrite:mo];
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

+ (NSArray*)findAllWithPredicate:(NSPredicate*)predicate sortDescriptors:(NSMutableArray*)sortDescriptors limit:(int)limit  inContext:(NSManagedObjectContext *)givenMoc forClass:(NSString*)className {
    NSManagedObjectContext *moc = givenMoc;
    if (!moc) {
        moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    }
    
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:className inManagedObjectContext:moc];
    
    if(predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    if (sortDescriptors) {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
    [fetchRequest setEntity:entity];
    if (limit > 0) {
        [fetchRequest setFetchLimit:limit];
    }
    
    // Preloading should only happen if there is no filter query and no limit.
    return [moc executeFetchRequest:fetchRequest error:&error];
}

+ (NSArray*)findAllWithPredicate:(NSPredicate*)predicate sortDescriptors:(NSMutableArray*)sortDescriptors limit:(int)limit inContext:(NSManagedObjectContext *)givenMoc {
    return [self findAllWithPredicate:predicate
               sortDescriptors:sortDescriptors
                         limit:limit inContext:givenMoc
                      forClass:[self entityName]];
}

+ (NSManagedObject*)findFirstWithPredicate:(NSPredicate*)predicate sortDescriptors:(NSMutableArray*)sortDescriptors inContext:(NSManagedObjectContext *)givenMoc {
    NSArray *results = [self findAllWithPredicate:predicate sortDescriptors:sortDescriptors limit:1 inContext:givenMoc];
    if ([results count] > 0){
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}


+ (NSArray*)getUpdatedRecordsForClass:(NSString*)className tillWriteId:(int)currentWriteId {
    Option *dataSentOption = [Option findWithKey:DBDataSentKey];
    int dataSentTill = [dataSentOption.value intValue];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"writeId > %i AND writeId <= %i", dataSentTill, currentWriteId];
    return [self findAllWithPredicate:pred
                      sortDescriptors:nil
                                limit:-1
                            inContext:nil
                             forClass:className];
}

@end
