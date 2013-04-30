//
//  SDSyncEngine.h
//  SignificantDates
//
//  Created by Chris Wagner on 7/1/12.
//

#import <Foundation/Foundation.h>

typedef enum {
    SDObjectSynced = 0,
} SDObjectSyncStatus;

@interface SDSyncEngine : NSObject

@property (atomic, readonly) BOOL syncInProgress;

+ (SDSyncEngine *)sharedEngine;
- (void)registerNSManagedObjectClassToSync:(Class)aClass;
- (void)startPostData;
- (void)startGetData;
- (void)setSeedData;
- (void)loadWriteId;
- (void)createAccountWithEmail:(NSString*)email;
- (void)searchAccountWithEmail:(NSString*)email;

@end
