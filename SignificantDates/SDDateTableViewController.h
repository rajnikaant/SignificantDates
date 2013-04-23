//
//  SDDateTableViewController.h
//  SignificantDates
//
//  Created by Chris Wagner on 6/1/12.
//

#import <UIKit/UIKit.h>
#import "Account.h"

@interface SDDateTableViewController : UITableViewController

@property (strong, nonatomic) NSManagedObjectID *managedObjectId;
@property (nonatomic, strong) NSArray *chapters;
@property (nonatomic, strong) NSArray *progresses;
@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, strong) Account *activeAccount;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
- (IBAction)refreshButtonTouched:(id)sender;
- (IBAction)sliderMoved:(UISlider *)slider;
@end
