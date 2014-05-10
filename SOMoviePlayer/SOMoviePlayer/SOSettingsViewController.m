//
//  SOSettingsViewController.m
//  SOMoviePlayer
//
//  Created by Stephen OHara on 23/02/14.
//  Copyright (c) 2014 Stephen OHara. All rights reserved.
//

#import "SOSettingsViewController.h"
#import "SONotifications.h"

@interface SOSettingsViewController ()
- (IBAction)onResetUp:(id)sender;
- (IBAction)onCloseUp:(id)sender;
- (IBAction)onZoom:(UISwitch *)sender;

@end

@implementation SOSettingsViewController

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
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.alpha = 0.7;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onResetUp:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kMotionManagerReset object:nil];

}

- (IBAction)onCloseUp:(id)sender {

    [UIView animateWithDuration:0.2
                         delay :0.0f
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.view.transform = CGAffineTransformMakeTranslation(0.0,320.0f);
                     }
                     completion:^(BOOL  complete){
                         
                         self.onCloseUpBlock();
                         [self removeFromParentViewController];
                     }
     ];

}

- (IBAction)onZoom:(UISwitch *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kZoomReset object:sender];
}
@end