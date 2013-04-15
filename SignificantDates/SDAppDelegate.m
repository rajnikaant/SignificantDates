//
//  SDAppDelegate.m
//  SignificantDates
//
//  Created by Chris Wagner on 5/14/12.
//

#import "SDAppDelegate.h"
#import "SDSyncEngine.h"
#import "Holiday.h"
#import "Birthday.h"

@implementation SDAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SDSyncEngine *sharedEngine = [SDSyncEngine sharedEngine];
    
    [sharedEngine registerNSManagedObjectClassToSync:[Holiday class]];
    [sharedEngine registerNSManagedObjectClassToSync:[Birthday class]];
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
    [[SDSyncEngine sharedEngine] startSync];
}

- (void)applicationWillTerminate:(UIApplication *)application
{

}

@end
