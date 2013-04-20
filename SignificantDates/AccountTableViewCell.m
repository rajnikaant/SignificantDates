//
//  AccountTableViewCell.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 18/04/13.
//
//

#import "AccountTableViewCell.h"

@implementation AccountTableViewCell

@synthesize accountName;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
