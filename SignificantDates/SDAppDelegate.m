//
//  SDAppDelegate.m
//  SignificantDates
//
//  Created by Chris Wagner on 5/14/12.
//

#import "SDAppDelegate.h"
#import "SDSyncEngine.h"
#import "Progress.h"
#import "Chapter.h"
#import "SDCoreDataController.h"
#import "Account.h"

@implementation SDAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SDSyncEngine *sharedEngine = [SDSyncEngine sharedEngine];
    
    [sharedEngine registerNSManagedObjectClassToSync:[Progress class]];
    [sharedEngine registerNSManagedObjectClassToSync:[Chapter class]];
    [sharedEngine setSeedData];
    [sharedEngine loadWriteId];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //sync if any account is present
    NSManagedObjectContext *moc = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    NSArray *accounts = [Account findAllWithPredicate:nil
                                      sortDescriptors:nil
                                                limit:-1 inContext:moc];
    if ([accounts count] > 0) {
        [[SDSyncEngine sharedEngine] startSync];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{

}

@end
