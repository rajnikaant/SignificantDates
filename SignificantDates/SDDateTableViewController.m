//
//  SDDateTableViewController.m
//  SignificantDates
//
//  Created by Chris Wagner on 6/1/12.
//

#import "SDDateTableViewController.h"
#import "SDCoreDataController.h"
#import "SDTableViewCell.h"
#import "SDAddDateViewController.h"
#import "SDDateDetailViewController.h"
#import "Holiday.h"
#import "Birthday.h"
#import "SDSyncEngine.h"
#import "Chapter.h"
#import "Progress.h"
#import "Constants.h"

static int sliderTagPrefix = 1000;
static int labelTagPrefix = 2000;

@interface SDDateTableViewController ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end

@implementation SDDateTableViewController

@synthesize dateFormatter;
@synthesize managedObjectContext;
@synthesize managedObjectId;

@synthesize entityName;
@synthesize refreshButton;
@synthesize chapters;
@synthesize progresses;
@synthesize activeAccount;
@synthesize animateSliders;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadRecordsFromCoreData {
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext reset];
        
        //active account
        self.activeAccount = (Account*)[self.managedObjectContext objectWithID:self.managedObjectId];
        
        //load all chapters
        self.chapters = [Chapter findAllWithPredicate:nil
                                      sortDescriptors:nil
                                                limit:-1
                                            inContext:self.managedObjectContext];
        
        self.progresses = [self.activeAccount allPogressesInContext:self.managedObjectContext];

    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.managedObjectContext = [[SDCoreDataController sharedInstance] newManagedObjectContext];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    [self loadRecordsFromCoreData];
  
    [[self navigationItem] setTitle:activeAccount.email];
    
    self.animateSliders = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self checkSyncStatus];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:SyncCompletedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self loadRecordsFromCoreData];
        self.animateSliders = YES;
        [self.tableView reloadData];
        self.animateSliders = NO;
    }];
    [[SDSyncEngine sharedEngine] addObserver:self forKeyPath:@"syncInProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SyncCompletedNotification object:nil];
    [[SDSyncEngine sharedEngine] removeObserver:self forKeyPath:@"syncInProgress"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        NSManagedObject *date = [self.dates objectAtIndex:indexPath.row];
//        [self.managedObjectContext performBlockAndWait:^{
//            [self.managedObjectContext deleteObject:date];
//            NSError *error = nil;
//            BOOL saved = [self.managedObjectContext save:&error];
//            if (!saved) {
//                NSLog(@"Error saving main context: %@", error);
//            }
//            
//            [[SDCoreDataController sharedInstance] saveMasterContext];
//            [self loadRecordsFromCoreData];
//            [self.tableView reloadData];
//        }];
//    }
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.chapters count];
}

-(Progress*)getProgressForChapter:(Chapter*)chapter {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"chapter = %@", chapter];
    NSArray *filteredProgresses = [self.progresses filteredArrayUsingPredicate:pred];
    if ([filteredProgresses count] > 0) {
        return (Progress*)[filteredProgresses objectAtIndex:0];
    }
    
    return nil;
}

-(int)updateProgress:(int)newProgress forChapterAtIndex:(int)chapIndex {
    //update the progress in memory so the rendering is correct the next time
    Chapter *chapter = [self.chapters objectAtIndex:chapIndex];
    Progress *prog = [self getProgressForChapter:chapter];
    int oldProgress = [prog.percent intValue];
    if (newProgress > oldProgress) {
        prog.percent = [NSNumber numberWithInt:newProgress];
        prog.writeId = [SDCoreDataController sharedInstance].writeId;
    
        //update the label text
        int labelTag = labelTagPrefix + chapIndex;
        UILabel *percentLabel = (UILabel*)[self.view viewWithTag:labelTag];
        percentLabel.text = [NSString stringWithFormat:@"%i%%", newProgress];
    }
    
    return ((newProgress > oldProgress) ? newProgress : oldProgress);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SDTableViewCell *cell = nil;
    
    static NSString *CellIdentifier = @"ChapterCell";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Chapter *chapter = [self.chapters objectAtIndex:indexPath.row];
    cell.chapNameLabel.text = chapter.name;

    Progress *chapProg = [self getProgressForChapter:chapter];
    cell.percentLabel.text = [NSString stringWithFormat:@"%@%%", [chapProg.percent stringValue]];
    cell.percentLabel.tag = labelTagPrefix + [self.chapters indexOfObject:chapter];
    
    [cell.chapProgressView setValue:[chapProg.percent intValue] animated:self.animateSliders];
    cell.chapProgressView.tag = sliderTagPrefix + [self.chapters indexOfObject:chapter];
    
    return cell;
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    if ([segue.identifier isEqualToString:@"ShowDateDetailViewSegue"]) {
//        SDDateDetailViewController *dateDetailViewController = segue.destinationViewController;
//        SDTableViewCell *cell = (SDTableViewCell *)sender;
//        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//        Holiday *holiday = [self.dates objectAtIndex:indexPath.row];
//        dateDetailViewController.managedObjectId = holiday.objectID;
//        
//    } else if ([segue.identifier isEqualToString:@"ShowAddDateViewSegue"]) {
//        SDAddDateViewController *addDateViewController = segue.destinationViewController;
//        [addDateViewController setAddDateCompletionBlock:^{
//            [self loadRecordsFromCoreData]; 
//            [self.tableView reloadData];
//        }];
//        
//    }
//}

- (void)viewDidUnload {
    [self setRefreshButton:nil];
    [super viewDidUnload];
}

- (IBAction)refreshButtonTouched:(id)sender {
    [[SDSyncEngine sharedEngine] startPostData];
}

- (void)checkSyncStatus {
    if ([[SDSyncEngine sharedEngine] syncInProgress]) {
        [self replaceRefreshButtonWithActivityIndicator];
    } else {
        [self removeActivityIndicatorFromRefreshButon];
    }
}

- (void)replaceRefreshButtonWithActivityIndicator {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [activityIndicator setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
    [activityIndicator startAnimating];
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.rightBarButtonItem = activityItem;
}

- (void)removeActivityIndicatorFromRefreshButon {
    self.navigationItem.rightBarButtonItem = self.refreshButton;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"syncInProgress"]) {
        [self checkSyncStatus];
    }
}

- (IBAction)sliderMoved:(UISlider *)slider {
    int chapIndex = slider.tag - sliderTagPrefix;
    int sliderValue = [[NSNumber numberWithFloat:slider.value] intValue];
    
    int finalProgress = [self updateProgress:sliderValue forChapterAtIndex:chapIndex];
    
    if (finalProgress == sliderValue) {
        [self.managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            BOOL saved = [self.managedObjectContext save:&error];
            if (!saved) {
                // do some real error handling
                NSLog(@"Could not save Date due to %@", error);
            }
            [[SDCoreDataController sharedInstance] saveMasterContext];
        }];
    } else {
        [slider setValue:[[NSNumber numberWithInt:finalProgress] floatValue] animated:YES];
    }

    

}
@end
