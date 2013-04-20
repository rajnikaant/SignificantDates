//
//  LoginViewController.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 18/04/13.
//
//

#import "LoginViewController.h"
#import "AccountTableViewCell.h"
#import "SDCoreDataController.h"
#import "Account.h"
#import "Constants.h"
#import "Chapter.h"

@interface LoginViewController ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end

@implementation LoginViewController

@synthesize accounts;
@synthesize accountsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)reloadAccounts {
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext reset];
        
        //load all accounts
        self.accounts = [Account findAllWithPredicate:nil
                                      sortDescriptors:nil
                                                limit:-1
                                            inContext:self.managedObjectContext];
    }];
}

- (void)viewDidLoad
{
    self.managedObjectContext = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    
    //load all the accounts in memory
    [self reloadAccounts];
    
    //listen to the reload table notification
    [[NSNotificationCenter defaultCenter] addObserverForName:kReloadAccountTableNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self reloadDisplayedAccounts];
                                                  }];
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.accounts count];
    }
    return 0;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountTableViewCell *cell = nil;
    
    static NSString *CellIdentifier = @"AccountIndentifier";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[AccountTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSLog(@"num accounts %i, object at index %i", [self.accounts count], indexPath.row);
    Account *account = ((Account*)[self.accounts objectAtIndex:indexPath.row]);
    NSLog(@"is NUll = %@", (!account) ? @"YES" : @"NO");
    NSLog(@"Account Email %@", account.email);
    [cell.accountName setText:account.email];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return ([self.accounts count] > 0 ? @"Existing Accounts" : @"No Accounts Available");
}

- (void)reloadDisplayedAccounts {
    [self dismissViewControllerAnimated:YES completion:nil];
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self reloadAccounts];
        [self.accountsTableView reloadData];
//    });
}

@end
