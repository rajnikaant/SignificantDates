//
//  CreateAccountViewController.h
//  SignificantDates
//
//  Created by Udit Sajjanhar on 18/04/13.
//
//

#import <UIKit/UIKit.h>

@interface CreateAccountViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextField *emailTextField;
@property (nonatomic, strong) IBOutlet UILabel *creatingAccount;
@property (nonatomic, strong) IBOutlet UIButton *createAccount;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) IBOutlet UITextField *searchTextField;
@property (nonatomic, strong) IBOutlet UILabel *searchingAccount;
@property (nonatomic, strong) IBOutlet UIButton *searchAccount;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *searchActivityIndicator;


@property (nonatomic, strong) IBOutlet UINavigationItem *navItem;

-(IBAction)create:(id)sender;

@end
