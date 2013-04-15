//
//  SDDateTableViewController.h
//  SignificantDates
//
//  Created by Chris Wagner on 6/1/12.
//

#import <UIKit/UIKit.h>

@class Player;

@interface SDDateTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *chapters;
@property (nonatomic, strong) NSArray *progresses;
@property (nonatomic, strong) Player *defaultPlayer;
@property (nonatomic, strong) NSString *entityName;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
- (IBAction)refreshButtonTouched:(id)sender;
- (IBAction)sliderMoved:(UISlider *)slider;
@end
