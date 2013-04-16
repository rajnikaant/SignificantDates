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
#import "Player.h"

@implementation SDAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SDSyncEngine *sharedEngine = [SDSyncEngine sharedEngine];
    
    [sharedEngine registerNSManagedObjectClassToSync:[Progress class]];
    [sharedEngine registerNSManagedObjectClassToSync:[Player class]];
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
    [[SDSyncEngine sharedEngine] startSync];
}

- (void)applicationWillTerminate:(UIApplication *)application
{

}

@end
