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
#import "Chapter.h"
#include <objc/runtime.h>

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

+(BOOL) isAccountEntity {
    return NO;
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

+ (NSArray*)findAllInContext:(NSManagedObjectContext*)givenMoc {
    return [self findAllWithPredicate:nil sortDescriptors:nil limit:-1 inContext:givenMoc];
}

+ (NSArray*)findAllWithPredicate:(NSPredicate*)predicate sortDescriptors:(NSMutableArray*)sortDescriptors limit:(int)limit  inContext:(NSManagedObjectContext *)givenMoc forClass:(NSString*)className {
    NSManagedObjectContext *moc = givenMoc;
    __block  NSArray *results;
    
    if (!moc) {
        moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    }
    
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
    [moc performBlockAndWait:^{
        NSError *error;
        results = [moc executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
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

+ (NSDictionary*)toSyncFormat:(id)object inContext:(NSManagedObjectContext*)moc {
    unsigned int count = 0;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *dontSyncProperties = [NSArray arrayWithObjects:@"writeId", @"account", @"updatedAt", nil];
    objc_property_t *properties = class_copyPropertyList([object class], &count);
    for( unsigned int i = 0; i < count; i++ ) {
        objc_property_t property = properties[i];
        const char* pName = property_getName(property);
        NSString *propertyName = [NSString stringWithCString:pName encoding:NSUTF8StringEncoding];
        if ([dontSyncProperties indexOfObject:propertyName] == NSNotFound) {
            id value; 
            if ([propertyName isEqualToString:@"chapter"]) {
                NSManagedObject *obj = [object valueForKey:propertyName];
                value = [obj valueForKey:@"slug"];
            } else {
                value = [object valueForKey:propertyName];
            }
            [dict setValue:value forKey:propertyName];
        }
    }
    free(properties);
    return dict;
}

+ (NSArray*)getUpdatedRecordsForClass:(NSString*)className tillWriteId:(int)currentWriteId forAccount:(Account *)acc {
    Option *dataSentOption = [Option findWithKey:DBDataSentKey];
    int dataSentTill = [dataSentOption.value intValue];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"writeId > %i AND writeId <= %i AND account = %@",
                         dataSentTill, currentWriteId, acc];
    
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    
    NSArray *updatedCoreDataRecords = [self findAllWithPredicate:pred
                                                 sortDescriptors:nil
                                                           limit:-1
                                                       inContext:moc
                                                        forClass:className];
    
    NSMutableArray *updatedRecords = [NSMutableArray array];
    for (int i = 0; i < [updatedCoreDataRecords count]; i++) {
        [updatedRecords addObject:[self toSyncFormat:[updatedCoreDataRecords objectAtIndex:i] inContext:moc]];
    }
    
    return updatedRecords;
}

@end
