//
//  ModalPopSegue.m
//  SignificantDates
//
//  Created by Udit Sajjanhar on 18/04/13.
//
//

#import "ModalPopSegue.h"

@implementation ModalPopSegue

- (void) perform {
    UIViewController *src = (UIViewController *) self.sourceViewController;
    [src dismissViewControllerAnimated:YES completion:nil];
}

@end
