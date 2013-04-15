//
//  SDTableViewCell.h
//  SignificantDates
//
//  Created by Chris Wagner on 5/25/12.
//

#import <UIKit/UIKit.h>

@interface SDTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *chapNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *percentLabel;
@property (nonatomic, strong) IBOutlet UIProgressView *chapProgressView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;

@end
