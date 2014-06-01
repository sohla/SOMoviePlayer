//
//  SOScreenTransport.m
//  SOMoviePlayer
//
//  Created by Stephen OHara on 30/05/2014.
//  Copyright (c) 2014 Stephen OHara. All rights reserved.
//

#import "SOScreenTransport.h"

@interface SOScreenTransport ()
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UILabel *attitudeLabel;


@end

@implementation SOScreenTransport

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
    // Do any additional setup after loading the view from its nib.
    
    self.backButton.layer.cornerRadius = self.backButton.frame.size.width / 2.0f;
    self.forwardButton.layer.cornerRadius = self.forwardButton.frame.size.width / 2.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onBackButton:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportBack object:sender];

}
- (IBAction)onForwardButton:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportForward object:sender];
}

-(void)updateAttitudeWithRoll:(float)roll andYaw:(float)yaw{
    self.attitudeLabel.text = [NSString stringWithFormat:@"roll %.2f yaw %.2f",roll,yaw];
}

@end
