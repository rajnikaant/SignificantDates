//
//  SDCoreDataController.h
//  SignificantDates
//
//  Created by Chris Wagner on 5/14/12.
//

#import <Foundation/Foundation.h>

@interface SDCoreDataController : NSObject

@property (atomic, retain) NSNumber *writeId;

+ (SDCoreDataController*)sharedInstance;

- (NSURL *)applicationDocumentsDirectory;

- (NSManagedObjectContext *)masterManagedObjectContext;
- (NSManagedObjectContext *)backgroundManagedObjectContext;
- (NSManagedObjectContext *)newManagedObjectContext;
- (void)saveMasterContext;
- (void)saveBackgroundContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

-(void)incrementWriteId;

@end
