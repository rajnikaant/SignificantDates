//
//  CreateAccountViewController.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 18/04/13.
//
//

#import "CreateAccountViewController.h"
#import "SDSyncEngine.h"
#import "Constants.h"
#import "Account.h"
#import "LoginViewController.h"

@interface CreateAccountViewController ()

@end

@implementation CreateAccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [self.creatingAccount setHidden:YES];
    [self.activityIndicator setHidden:YES];
    [self.createAccount.titleLabel setText:@"Create Account"];

    [self.searchingAccount setHidden:YES];
    [self.searchActivityIndicator setHidden:YES];
    [self.searchAccount setTitle:@"Search Account" forState:UIControlStateNormal];
    [self.searchAccount setTitle:@"Search Account" forState:UIControlStateHighlighted];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kAccountCreateFailedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self createFailed];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kAccountSearchFailedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self searchFailed];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kAccountSearchNoResultNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self noSearchResults];
                                                  }];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    [self removeObservers];
    [super viewDidDisappear:animated];
}

-(IBAction)search:(id)sender {
    NSString *email = self.searchTextField.text;
    if (email && !([email isEqualToString:@""])) {
        [self.searchAccount setHidden:YES];
        [self.searchingAccount setHidden:NO];
        [self.searchActivityIndicator setHidden:NO];
        [[self.navItem leftBarButtonItem] setEnabled:NO];
        [self.searchTextField setEnabled:NO];
        [[SDSyncEngine sharedEngine] searchAccountWithEmail:email];
    }
}

-(IBAction)create:(id)sender {
    NSString *email = self.emailTextField.text;
    if (email && !([email isEqualToString:@""])) {
        [self.createAccount setHidden:YES];
        [self.creatingAccount setHidden:NO];
        [self.activityIndicator setHidden:NO];
        [[self.navItem leftBarButtonItem] setEnabled:NO];
        [self.emailTextField setEnabled:NO];
        [[SDSyncEngine sharedEngine] createAccountWithEmail:email];
    }
}

-(void)createFailed {
    [self.creatingAccount setHidden:YES];
    [self.activityIndicator setHidden:YES];
    [self.createAccount setHidden:NO];
    [self.createAccount.titleLabel setText:@"Failed, Try Again"];
    [[self.navItem leftBarButtonItem] setEnabled:YES];
    [self.emailTextField setEnabled:YES];
}

-(void)searchFailed {
    [self.searchingAccount setHidden:YES];
    [self.searchActivityIndicator setHidden:YES];
    [self.searchAccount setHidden:NO];
    [self.searchAccount.titleLabel setText:@"Failed, Try Again"];
    [[self.navItem leftBarButtonItem] setEnabled:YES];
    [self.searchTextField setEnabled:YES];
}

-(void)noSearchResults {
    [self.searchingAccount setHidden:YES];
    [self.searchActivityIndicator setHidden:YES];
    [self.searchAccount setHidden:NO];
    [self.searchAccount setTitle:@"No Results" forState:UIControlStateNormal];
//    [self.searchAccount.titleLabel setText:@"No Results"];
    [[self.navItem leftBarButtonItem] setEnabled:YES];
    [self.searchTextField setEnabled:YES];
}

-(void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAccountCreateFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAccountSearchFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAccountSearchNoResultNotification object:nil];
}

@end

