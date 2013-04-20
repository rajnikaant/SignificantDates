//
//  LoginViewController.h
//  SignificantDates
//
//  Created by Udit Sajjanhar on 18/04/13.
//
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/* list of all user accounts on this device */
@property (nonatomic, retain) NSArray *accounts;
@property (nonatomic, retain) IBOutlet UITableView *accountsTableView;

-(void) reloadDisplayedAccounts;

@end
