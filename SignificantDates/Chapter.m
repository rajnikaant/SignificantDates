//
//  Chapter.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 15/04/13.
//
//

#import "Chapter.h"
#import "Progress.h"


@implementation Chapter

@dynamic name;
@dynamic progress;
@dynamic updatedAt;
@dynamic writeId;


+(NSString*)entityName {
    return @"Chapter";
}

@end
