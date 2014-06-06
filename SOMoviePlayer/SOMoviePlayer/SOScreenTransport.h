//
//  SOScreenTransport.h
//  SOMoviePlayer
//
//  Created by Stephen OHara on 30/05/2014.
//  Copyright (c) 2014 Stephen OHara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SONotifications.h"
#import "SOSettingsViewController.h"

@interface SOScreenTransport : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *selectedLabel;

-(void)updateAttitudeWithRoll:(float)roll andYaw:(float)yaw;
@end
