//
//  SDSyncEngine.m
//  SignificantDates
//
//  Created by Chris Wagner on 7/1/12.
//

#import "SDSyncEngine.h"
#import "SDCoreDataController.h"
#import "SDAFParseAPIClient.h"
#import "AFHTTPRequestOperation.h"
#import "Option.h"
#import "Chapter.h"
#import "Progress.h"
#import "Constants.h"
#import "Account.h"

NSString * const kSDSyncEngineInitialCompleteKey = @"SDSyncEngineInitialSyncCompleted";
NSString * const kSDSyncEngineSyncDefaultSyncEntryAdded = @"SDSyncEngineSyncDefaultSync";


@interface SDSyncEngine ()

@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic) int currentSyncWriteId;

@end

@implementation SDSyncEngine

@synthesize syncInProgress = _syncInProgress;
@synthesize currentSyncWriteId;

@synthesize registeredClassesToSync = _registeredClassesToSync;
@synthesize dateFormatter = _dateFormatter;

+ (SDSyncEngine *)sharedEngine {
    static SDSyncEngine *sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[SDSyncEngine alloc] init];
    });
    
    return sharedEngine;
}

- (void)loadWriteId {
    NSNumber *writeId = [NSNumber numberWithInt:[[Option findWithKey:DBWriteIdKey].value intValue]];
    [[SDCoreDataController sharedInstance] setWriteId:writeId];
}

- (void)setSeedData {
    //dataSent and writeId keys
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    BOOL defaultEntryAdded = [[standardDefaults valueForKey:kSDSyncEngineSyncDefaultSyncEntryAdded] boolValue];
    if (!defaultEntryAdded) {
        [[SDCoreDataController sharedInstance] setWriteId:[NSNumber numberWithInt:0]];
        NSArray *keys = [NSArray arrayWithObjects:DBWriteIdKey, DBDataSentKey, nil];
        NSArray *values = [NSArray arrayWithObjects:@"1", @"0", nil];
        [Option createWithKeys:keys andValues:values];
        
        NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];

        //default chapters
        int i=0;
        for (i = 1; i < 9; i++) {
            NSString *chapterName = [NSString stringWithFormat:@"Chapter %i", i];
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:chapterName forKey:@"name"];
            [dict setValue:[NSString stringWithFormat:@"chap_%i", i] forKey:@"slug"];
            [Chapter createWithDictionary:dict inContext:moc];
        }
        
        [self loadWriteId];
    }
    
    [standardDefaults setValue:@"YES" forKey:kSDSyncEngineSyncDefaultSyncEntryAdded];
    
}

- (void)getDataForRegisteredObjects {
    //find updated records for each account
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    NSMutableArray *allAccountsInfo = [NSMutableArray array];
    
    NSArray *accounts = [Account findAllInContext:moc];
    for (Account *acc in accounts) {
        NSMutableDictionary *accountData = [NSMutableDictionary dictionary];
        [accountData setValue:acc.gspid forKey:@"gspid"];
        [accountData setValue:acc.clientId forKey:@"client_id"];
        [accountData setValue:acc.authToken forKey:@"auth_token"];
        [accountData setValue:acc.serverLastSyncedWriteId forKey:@"client_last_synced_write_id"];
        [allAccountsInfo addObject:accountData];
    }
    
    if ([allAccountsInfo count] > 0) {
        NSError* error = nil;
        NSData *jsonData =
            [NSJSONSerialization dataWithJSONObject:allAccountsInfo options:nil error:&error];
        if (!error) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSMutableURLRequest *request = [[SDAFParseAPIClient sharedClient] GETRequestForDataWithJSONString:jsonString];
                AFHTTPRequestOperation *operation =
                [[SDAFParseAPIClient sharedClient]
                 HTTPRequestOperationWithRequest:request
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     [self executeDataReceivedOperationsWithStatus:YES andResponse:responseObject];
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     [self executeDataReceivedOperationsWithStatus:NO andResponse:nil];
                     NSLog(@"sync request failed %@", [error description]);
                 }];
                
                [operation start];
            });
        }
    }

}

- (void)sendDataForRegisteredObjects {
    //array with data of all updated accounts
    NSMutableArray *updatedAccounts = [NSMutableArray array];
    
    //store the current writeId
    int currentWriteId = [[SDCoreDataController sharedInstance].writeId intValue];
    self.currentSyncWriteId = currentWriteId;
    
    //increment the writeId
    [[SDCoreDataController sharedInstance] incrementWriteId];
    
    //find updated records for each account
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    NSArray *accounts = [Account findAllInContext:moc];
    for (Account *acc in accounts) {
        NSDictionary *updatedRecords = [self getUpdatedRecordsSinceLastDataSentTillWriteId:currentWriteId
                                                                                forAccount:acc];
        if ([[updatedRecords allKeys] count] > 0) {
            NSMutableDictionary *accountData = [NSMutableDictionary dictionary];
            [accountData setValue:acc.gspid forKey:@"gspid"];
            [accountData setValue:acc.clientId forKey:@"client_id"];
            [accountData setValue:acc.authToken forKey:@"auth_token"];
            [accountData setValue:updatedRecords forKey:@"records"];
            [updatedAccounts addObject:accountData];
        }
    }
    
    if ([updatedAccounts count] > 0) {
        //prepare a json fo the dictionary
        NSError* error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:updatedAccounts
                                                           options:nil
                                                             error:&error];
        if (!error) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//            NSLog(jsonString);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSMutableURLRequest *request = [[SDAFParseAPIClient sharedClient] POSTRequestForSendDataWithJSONString:jsonString];
//                [request setTimeoutInterval:10];
                AFHTTPRequestOperation *operation =
                [[SDAFParseAPIClient sharedClient]
                 HTTPRequestOperationWithRequest:request
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     [self executeDataSentOperationsWithStatus:YES];
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     [self executeDataSentOperationsWithStatus:NO];
                     NSLog(@"sync request failed %@", [error description]);
                 }];
                
                [operation start];
            });
            return;
        }
    }
    [self executeDataSentOperationsWithStatus:YES];
 }

-(NSDictionary*)getUpdatedRecordsSinceLastDataSentTillWriteId:(int)currentWriteId forAccount:(Account*)acc {
    NSMutableDictionary *updatedRecords = [NSMutableDictionary dictionary];
    for (NSString *className in self.registeredClassesToSync) {
        NSArray *updatedRecordsForClass = [BaseModel getUpdatedRecordsForClass:className tillWriteId:currentWriteId forAccount:acc];
        if ([updatedRecordsForClass count] > 0)
            [updatedRecords setValue:updatedRecordsForClass forKey:className];
    }
    return updatedRecords;
}

- (void)registerNSManagedObjectClassToSync:(Class)aClass {
    if (!self.registeredClassesToSync) {
        self.registeredClassesToSync = [NSMutableArray array];
    }
    
    if ([aClass isSubclassOfClass:[NSManagedObject class]]) {        
        if (![self.registeredClassesToSync containsObject:NSStringFromClass(aClass)]) {
            [self.registeredClassesToSync addObject:NSStringFromClass(aClass)];
        } else {
            NSLog(@"Unable to register %@ as it is already registered", NSStringFromClass(aClass));
        }
    } else {
        NSLog(@"Unable to register %@ as it is not a subclass of NSManagedObject", NSStringFromClass(aClass));
    }
}

- (void)startGetData {
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self getDataForRegisteredObjects];
        });
    }
}

- (void)startPostData {
    if (!self.syncInProgress) {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self sendDataForRegisteredObjects];
        });
    }
}

- (void)searchAccountWithEmail:(NSString *)email {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableURLRequest *request = [[SDAFParseAPIClient sharedClient] POSTRequestForAccountSearchWithEmail:email];
        AFHTTPRequestOperation *operation =
        [[SDAFParseAPIClient sharedClient]
         HTTPRequestOperationWithRequest:request
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"number of keys %i", [[responseObject allKeys] count]);
             if ([[responseObject allKeys] count] == 0) {
                 [[NSNotificationCenter defaultCenter] postNotificationName:kAccountSearchNoResultNotification
                                                                     object:nil
                                                                   userInfo:responseObject];
             } else {
                 //create account in DB
                 [Account createWithParams:responseObject];
                 
                 [[NSNotificationCenter defaultCenter] postNotificationName:kReloadAccountTableNotification
                                                                     object:nil
                                                                   userInfo:responseObject];
                 [[SDSyncEngine sharedEngine] startPostData];
             }

         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"create request failed");
             [[NSNotificationCenter defaultCenter] postNotificationName:kAccountSearchFailedNotification
                                                                 object:nil];
         }];
        
        [operation start];
    });
}

- (void)createAccountWithEmail:(NSString*)email {
    //only one account will be created at one time
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableURLRequest *request = [[SDAFParseAPIClient sharedClient] POSTRequestForAccountCreateWithEmail:email];
        AFHTTPRequestOperation *operation =
            [[SDAFParseAPIClient sharedClient]
                HTTPRequestOperationWithRequest:request
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    //create account in DB
                    [Account createWithParams:responseObject];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kReloadAccountTableNotification
                                                                        object:nil
                                                                      userInfo:responseObject];
                    }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"create request failed");
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAccountCreateFailedNotification
                                                                        object:nil];
                    }];
        
        [operation start];
    });
}

-(void)setSyncCompleted {
    //save the contexts
    [[SDCoreDataController sharedInstance] saveBackgroundContext];
    [[SDCoreDataController sharedInstance] saveMasterContext];
    
    [self willChangeValueForKey:@"syncInProgress"];
    _syncInProgress = NO;
    [self didChangeValueForKey:@"syncInProgress"];
}

- (void)executeDataReceivedOperationsWithStatus:(BOOL)successful andResponse:(NSArray*)response {
    NSLog(@"Data get operation complete");
    
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] backgroundManagedObjectContext];
    BOOL newDataArrived = NO;

    if (successful) {
        //process the records
        NSLog(@"the records are %@", [response description]);
        
        for (NSDictionary *accountInfo in response) {
            newDataArrived = YES;
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"gspid = %@", [accountInfo valueForKey:@"gspid"]];
            Account *acc = (Account*)[Account findFirstWithPredicate:pred
                                           sortDescriptors:nil
                                                 inContext:moc];
            if (acc) {
                int lastSyncedId = [[accountInfo valueForKey:@"client_last_synced_write_id"] intValue];
                acc.serverLastSyncedWriteId = [NSNumber numberWithInt:lastSyncedId];
                
                NSArray *chapters = [Chapter findAllInContext:moc];
                NSArray *accountProgresses = [acc allPogressesInContext:moc];
                
                NSArray *progressRecords = [[accountInfo valueForKey:@"records"] valueForKey:@"Progress"];
                for (NSDictionary *progressRecord in progressRecords) {
                    NSString *recSlug = [progressRecord valueForKey:@"chapter_slug"];
                    NSPredicate *chapPred = [NSPredicate predicateWithFormat:@"slug = %@", recSlug];
                    Chapter *recChap = [[chapters filteredArrayUsingPredicate:chapPred] objectAtIndex:0];
                    NSPredicate *progPred = [NSPredicate predicateWithFormat:@"chapter = %@", recChap];
                    Progress *prog = [[accountProgresses filteredArrayUsingPredicate:progPred] objectAtIndex:0];
                    prog.percent = [NSNumber numberWithInt:[[progressRecord valueForKey:@"percent"] intValue]];
                }
            }
        }
    }
    
    [self setSyncCompleted];
    
    if (newDataArrived) {
        NSLog(@"new data arrived");
        [[NSNotificationCenter defaultCenter] postNotificationName:SyncCompletedNotification
                                                            object:nil
                                                          userInfo:nil];
    }
}

- (void)executeDataSentOperationsWithStatus:(BOOL)successful {
    NSLog(@"Data sent operation complete");
    dispatch_async(dispatch_get_main_queue(), ^{
        //update the data sent key if successful
        if (successful) {
            [Option setValue:[[NSNumber numberWithInt:self.currentSyncWriteId] stringValue]
                      forKey:DBDataSentKey];
        }
        
        //unset the current sync id
        self.currentSyncWriteId = -1;
        
        //previous app
        [self setInitialSyncCompleted];

        //mark sync as completed
        [self setSyncCompleted];
        
        //start the get request, if data was posted successfully
        if (successful) {
            [self startGetData];
        }
    });
}


- (BOOL)initialSyncComplete {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kSDSyncEngineInitialCompleteKey] boolValue];
}

- (void)setInitialSyncCompleted {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kSDSyncEngineInitialCompleteKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)mostRecentUpdatedAtDateForEntityWithName:(NSString *)entityName {
    __block NSDate *date = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [request setSortDescriptors:[NSArray arrayWithObject:
                                 [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]]];
    [request setFetchLimit:1];
    [[[SDCoreDataController sharedInstance] backgroundManagedObjectContext] performBlockAndWait:^{
        NSError *error = nil;
        NSArray *results = [[[SDCoreDataController sharedInstance] backgroundManagedObjectContext] executeFetchRequest:request error:&error];
        if ([results lastObject])   {
            date = [[results lastObject] valueForKey:@"updatedAt"];
        }
    }];
    
    return date;
}



- (void)downloadDataForRegisteredObjects:(BOOL)useUpdatedAtDate {
//    NSMutableArray *operations = [NSMutableArray array];
//    
//    for (NSString *className in self.registeredClassesToSync) {
//        NSDate *mostRecentUpdatedDate = nil;
//        if (useUpdatedAtDate) {
//            mostRecentUpdatedDate = [self mostRecentUpdatedAtDateForEntityWithName:className];
//        }
//        NSMutableURLRequest *request = [[SDAFParseAPIClient sharedClient]
//                                        GETRequestForAllRecordsOfClass:className 
//                                        updatedAfterDate:mostRecentUpdatedDate];
//        AFHTTPRequestOperation *operation = [[SDAFParseAPIClient sharedClient] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            if ([responseObject isKindOfClass:[NSDictionary class]]) {
//                [self writeJSONResponse:responseObject toDiskForClassWithName:className];
//            }            
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"Request for class %@ failed with error: %@", className, error);
//        }];
//        
//        [operations addObject:operation];
//    }
//    
//    [[SDAFParseAPIClient sharedClient] enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
//        
//    } completionBlock:^(NSArray *operations) {
//
//        if (useUpdatedAtDate) {
//            [self processJSONDataRecordsIntoCoreData];
//        } 
////        else {
////            [self processJSONDataRecordsForDeletion];
////        }
//    }];
}

- (void)processJSONDataRecordsIntoCoreData {
    NSManagedObjectContext *managedObjectContext = [[SDCoreDataController sharedInstance] backgroundManagedObjectContext];
    for (NSString *className in self.registeredClassesToSync) {
        if (![self initialSyncComplete]) { // import all downloaded data to Core Data for initial sync
            NSDictionary *JSONDictionary = [self JSONDictionaryForClassWithName:className];
            NSArray *records = [JSONDictionary objectForKey:@"results"];
            for (NSDictionary *record in records) {
                [self newManagedObjectWithClassName:className forRecord:record];
            }
        } else {
            NSArray *downloadedRecords = [self JSONDataRecordsForClass:className sortedByKey:@"objectId"];
            if ([downloadedRecords lastObject]) {
                NSArray *storedRecords = [self managedObjectsForClass:className sortedByKey:@"objectId" usingArrayOfIds:[downloadedRecords valueForKey:@"objectId"] inArrayOfIds:YES];
                int currentIndex = 0;
                for (NSDictionary *record in downloadedRecords) {
                    NSManagedObject *storedManagedObject = nil;
                    if ([storedRecords count] > currentIndex) {
                        storedManagedObject = [storedRecords objectAtIndex:currentIndex];
                    }
                    
                    if ([[storedManagedObject valueForKey:@"objectId"] isEqualToString:[record valueForKey:@"objectId"]]) {
                        [self updateManagedObject:[storedRecords objectAtIndex:currentIndex] withRecord:record];
                    } else {
                        [self newManagedObjectWithClassName:className forRecord:record];
                    }
                    currentIndex++;
                }
            }
        }
        
        [managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            if (![managedObjectContext save:&error]) {
                NSLog(@"Unable to save context for class %@", className);
            }
        }];
        
        [self deleteJSONDataRecordsForClassWithName:className];
//        [self executeSyncCompletedOperations];
    }
    
    [self downloadDataForRegisteredObjects:NO];
}

- (void)newManagedObjectWithClassName:(NSString *)className forRecord:(NSDictionary *)record {
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:[[SDCoreDataController sharedInstance] backgroundManagedObjectContext]];
    [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key forManagedObject:newManagedObject];
    }];
    [record setValue:[NSNumber numberWithInt:SDObjectSynced] forKey:@"syncStatus"];
}

- (void)updateManagedObject:(NSManagedObject *)managedObject withRecord:(NSDictionary *)record {
    [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key forManagedObject:managedObject];
    }];
}

- (void)setValue:(id)value forKey:(NSString *)key forManagedObject:(NSManagedObject *)managedObject {
    if ([key isEqualToString:@"createdAt"] || [key isEqualToString:@"updatedAt"]) {
        NSDate *date = [self dateUsingStringFromAPI:value];
        [managedObject setValue:date forKey:key];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        if ([value objectForKey:@"__type"]) {
            NSString *dataType = [value objectForKey:@"__type"];
            if ([dataType isEqualToString:@"Date"]) {
                NSString *dateString = [value objectForKey:@"iso"];
                NSDate *date = [self dateUsingStringFromAPI:dateString];
                [managedObject setValue:date forKey:key];
            } else if ([dataType isEqualToString:@"File"]) {
                NSString *urlString = [value objectForKey:@"url"];
                NSURL *url = [NSURL URLWithString:urlString];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                NSURLResponse *response = nil;
                NSError *error = nil;
                NSData *dataResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                [managedObject setValue:dataResponse forKey:key];
            } else {
                NSLog(@"Unknown Data Type Received");
                [managedObject setValue:nil forKey:key];
            }
        }
    } else {
        [managedObject setValue:value forKey:key];
    }
}

- (NSArray *)managedObjectsForClass:(NSString *)className withSyncStatus:(SDObjectSyncStatus)syncStatus {
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[SDCoreDataController sharedInstance] backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"syncStatus = %d", syncStatus];
    [fetchRequest setPredicate:predicate];
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;    
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key usingArrayOfIds:(NSArray *)idArray inArrayOfIds:(BOOL)inIds {
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[SDCoreDataController sharedInstance] backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSPredicate *predicate;
    if (inIds) {
        predicate = [NSPredicate predicateWithFormat:@"objectId IN %@", idArray];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"NOT (objectId IN %@)", idArray];
    }
    
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:
                                      [NSSortDescriptor sortDescriptorWithKey:@"objectId" ascending:YES]]];
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
}

- (void)initializeDateFormatter {
    if (!self.dateFormatter) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [self.dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }
}

- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString {
    [self initializeDateFormatter];
    // NSDateFormatter does not like ISO 8601 so strip the milliseconds and timezone
    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-5)];
    
    return [self.dateFormatter dateFromString:dateString];
}

- (NSString *)dateStringForAPIUsingDate:(NSDate *)date {
    [self initializeDateFormatter];
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    // remove Z
    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-1)];
    // add milliseconds and put Z back on
    dateString = [dateString stringByAppendingFormat:@".000Z"];
    
    return dateString;
}

#pragma mark - File Management

- (NSURL *)applicationCacheDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)JSONDataRecordsDirectory{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *url = [NSURL URLWithString:@"JSONRecords/" relativeToURL:[self applicationCacheDirectory]];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[url path]]) {
        [fileManager createDirectoryAtPath:[url path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return url;
}

- (void)writeJSONResponse:(id)response toDiskForClassWithName:(NSString *)className {
    NSURL *fileURL = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    if (![(NSDictionary *)response writeToFile:[fileURL path] atomically:YES]) {
        NSLog(@"Error saving response to disk, will attempt to remove NSNull values and try again.");
        // remove NSNulls and try again...
        NSArray *records = [response objectForKey:@"results"];
        NSMutableArray *nullFreeRecords = [NSMutableArray array];
        for (NSDictionary *record in records) {
            NSMutableDictionary *nullFreeRecord = [NSMutableDictionary dictionaryWithDictionary:record];
            [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([obj isKindOfClass:[NSNull class]]) {
                    [nullFreeRecord setValue:nil forKey:key];
                }
            }];
            [nullFreeRecords addObject:nullFreeRecord];
        }
        
        NSDictionary *nullFreeDictionary = [NSDictionary dictionaryWithObject:nullFreeRecords forKey:@"results"];
        
        if (![nullFreeDictionary writeToFile:[fileURL path] atomically:YES]) {
            NSLog(@"Failed all attempts to save reponse to disk: %@", response);
        }
    }
}

- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className {
    NSURL *url = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]];
    NSError *error = nil;
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    if (!deleted) {
        NSLog(@"Unable to delete JSON Records at %@, reason: %@", url, error);
    }
}

- (NSDictionary *)JSONDictionaryForClassWithName:(NSString *)className {
    NSURL *fileURL = [NSURL URLWithString:className relativeToURL:[self JSONDataRecordsDirectory]]; 
    return [NSDictionary dictionaryWithContentsOfURL:fileURL];
}

- (NSArray *)JSONDataRecordsForClass:(NSString *)className sortedByKey:(NSString *)key {
    NSDictionary *JSONDictionary = [self JSONDictionaryForClassWithName:className];
    NSArray *records = [JSONDictionary objectForKey:@"results"];
    return [records sortedArrayUsingDescriptors:[NSArray arrayWithObject:
                                                 [NSSortDescriptor sortDescriptorWithKey:key ascending:YES]]];
}
@end
