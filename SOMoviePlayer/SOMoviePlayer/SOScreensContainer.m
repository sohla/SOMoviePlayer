//
//  SODetailViewController.m
//  SOMoviePlayer
//
//  Created by Stephen OHara on 17/02/14.
//  Copyright (c) 2014 Stephen OHara. All rights reserved.
//

#import "SOScreensContainer.h"
#import "SONotifications.h"
#import "SOPropertiesViewController.h"
#import "SOScreenViewController.h"
#import "SOFloatTransformer.h"
#import "SOAppDelegate.h"
#import "SOCameraViewController.h"
#import "SOTouchView.h"



@interface SOScreensContainer ()

@property (strong, nonatomic) CADisplayLink             *displayLink;
@property (strong, nonatomic) NSMutableDictionary       *screenViewControllers;

@property (strong, nonatomic) SOScreenTransport         *transport;
@property (weak, nonatomic) SOCueModel *selectedCueModel;
@property (assign, nonatomic) SOBeaconModel *currentBeaconModel;
@property (strong, nonatomic) SOCameraViewController *cvc;
@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) UIViewController *pauseViewController;
@property (strong, nonatomic) SOTouchView *touchView;

@property (strong, nonatomic)UISwipeGestureRecognizer *swipeRightGesture;
@property (strong, nonatomic)UISwipeGestureRecognizer *swipeLeftGesture;

-(void)onMotionManagerReset:(NSNotification *)notification;



@end

@implementation SOScreensContainer





#pragma mark - Views

- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    
//    [[NSUserDefaults standardUserDefaults] setObject:@(YES)  forKey:kLastEditState];
//    [[NSUserDefaults standardUserDefaults] synchronize];

//#if !TARGET_IPHONE_SIMULATOR
//    self.cvc = [[SOCameraViewController alloc] initWithNibName:@"SOCameraViewController" bundle:nil];
//    [self.view addSubview:self.cvc.view];
//#endif
    
    [self.view sendSubviewToBack:self.cvc.view];
    
    _screenViewControllers = [[NSMutableDictionary alloc] init];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    //motion
    [self addDisplayLink];

    [self addObservers];

    [self addGestures];
    
    CGRect fullFrame = CGRectMake(0.0, 0.0,
                                  self.view.frame.size.height,
                                  self.view.frame.size.width);

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _transport = [sb instantiateViewControllerWithIdentifier:@"transportVCID"];

    _pauseViewController = [sb instantiateViewControllerWithIdentifier:@"pauseVCID"];
    [self.pauseViewController.view setFrame:self.view.frame];
    [self.view addSubview:self.pauseViewController.view];
    [self.pauseViewController.view setTransform:CGAffineTransformMakeTranslation(-self.view.frame.size.width, 0.0)];
     
    
    
//    CGRect touchRect = CGRectInset(self.view.frame, 30.0, 30.0);
//    _touchView = [[SOTouchView alloc] initWithFrame:touchRect];
//    [self.view addSubview:self.touchView];
    
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:kLastEditState]){
        [self addChildViewController:self.transport];
        [self.transport.view setFrame:fullFrame];
        [self.transport.view setAlpha:0.5f];
        [self.view addSubview:self.transport.view];
        
    }

    _nextButton = [[UIButton alloc] initWithFrame:CGRectOffset( CGRectInset(self.view.frame, 120.0f, 120.0f), 0, 100.0)];
    [self.nextButton setTitle:@"Shake to continue" forState:UIControlStateNormal];
    [self.nextButton setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.7]];
    [self.nextButton .layer setCornerRadius:7.0f];
    [self.nextButton addTarget:self action:@selector(onNextButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    self.nextButton.alpha = 0.0f;

    
}
-(void)dealloc{
    DLog(@"");
    //[self.screenViewControllers removeAllObjects];
    
}
-(void)viewWillAppear:(BOOL)animated{
    
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    [[self tabBarController].tabBar setHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [[self tabBarController].tabBar setHidden:NO];
}

-(void)cleanup{
    
    DLog(@"");
    
    [self removeGestures];
    [self removeObservers];
    }
- (void)viewDidUnload{
    
    [self cleanup];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL)canBecomeFirstResponder{
    return YES;
}
#pragma mark - Motion Manager

-(void)addDisplayLink{
    
    if(self.displayLink==nil){
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }

}

-(void)removeDisplayLink{
    
    if(self.displayLink!=nil)
        [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = nil;
}

-(void)playCue:(SOCueModel*)cueModel{
    
    SOScreenViewController *svc = [[SOScreenViewController alloc] initWithFrame:self.view.bounds];
    [svc setDelegate:self];
    [svc setCueModel:cueModel];

    [self.screenViewControllers setObject:svc forKey:[cueModel title]];
    
    [self.view addSubview:svc.view];

    [self.view bringSubviewToFront:svc.view];
    [self.view bringSubviewToFront:self.transport.view];
//    [self.view bringSubviewToFront:self.touchView];
    
    if([cueModel.type isEqualToString:@"audio"]){
        [svc.view setHidden:YES];
    }
    
    [self.view sendSubviewToBack:self.cvc.view];

    if(cueModel.trigger){
        DLog(@"WE CAN TRIGGER");
        [self nextButtonOn:YES withDelay:cueModel.trigger];
    }else{
    }

    [self.view bringSubviewToFront:self.nextButton];
}

-(void)stopCue:(SOCueModel*)cueModel{
    
    SOScreenViewController *svc = [self.screenViewControllers objectForKey:cueModel.title];
    
    if(svc){
        [svc stopWithcompletionBlock:^{
            
        }];
    }
}

-(void)nextButtonOn:(BOOL)isOn withDelay:(float)delay{
    
    if(isOn){
        
        self.nextButton.alpha = 0.0f;

        [UIView animateWithDuration:1.0f delay:delay options:0 animations:^{
            self.nextButton.alpha = 1.0f;
        } completion:^(BOOL finished) {
            self.nextButton.selected = YES;
        }];
        
    }else{

        self.nextButton.alpha = 1.0f;
        self.nextButton.selected = NO;
        
        [UIView animateWithDuration:0.4f animations:^{
            self.nextButton.alpha = 0.0f;

        }];

    }
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{

    if (motion == UIEventSubtypeMotionShake && self.nextButton.selected){
        
        DLog(@"*");
        [[NSNotificationCenter defaultCenter] postNotificationName:kTransportNext object:nil];
        [self nextButtonOn:NO withDelay:0.0f];
        
        // play a sound
        SystemSoundID completeSound;
        NSURL *audioPath = [NSURL fileURLWithPath: [[NSBundle mainBundle]  pathForResource:@"harp" ofType:@"mp3"]];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &completeSound);
        AudioServicesPlaySystemSound (completeSound);
    }
}

-(void)onNextButton:(id)sender{

    DLog(@"");
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportNext object:nil];
    [self nextButtonOn:NO withDelay:0.0f];
}

#pragma mark - Beacon

-(void)triggerBeacon:(SOBeaconModel*)beaconModel{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    DLog(@"TRIGGER %d",beaconModel.minor);
    
    self.currentBeaconModel = beaconModel;
    
    // if we are a movie
    [beaconModel.cues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        __block SOCueModel *cueModel = [self.modelStore cueModelWithTitle:obj];
        DLog(@"cueing : %@",cueModel.path);

        float pre_time = [[SOFloatTransformer transformValue:[NSNumber numberWithFloat:cueModel.pre_time]
                                             valWithPropName:@"pre_time"] floatValue];
        
        if([cueModel.type isEqualToString:@"cam"]){

            [self performSelector:@selector(playCam:) withObject:cueModel afterDelay:pre_time];
            
        }else{
            
            [self performSelector:@selector(playCue:) withObject:cueModel afterDelay:pre_time];
        }
        
    }];
    
}

-(void)playCam:(SOCueModel *)cueModel{

#if !TARGET_IPHONE_SIMULATOR

    self.cvc = [[SOCameraViewController alloc] initWithNibName:@"SOCameraViewController" bundle:nil];
    [self.view addSubview:self.cvc.view];
#endif
    
    self.cvc.view.alpha = 0.0f;
    
    [UIView animateWithDuration:5.0f
                          delay: 0.0f
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.cvc.view.alpha = 1.0f;
                     }
                     completion:nil];

    
    [UIView animateWithDuration:5.0f
                          delay: (cueModel.fadeout_time * 10.0f)
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.cvc.view.alpha = 1.0f;
                     }
                     completion:nil];

    
}
#pragma mark - ScreenView Protocol

-(void)onScreenViewPlayerDidBegin:(SOScreenViewController*)svc{
    //DLog(@"");
}

-(void)onScreenViewPlayerDidEnd:(SOScreenViewController*)svc{

    DLog(@"removing svc for %@",[[svc getCueModel] title]);
    [self.screenViewControllers removeObjectForKey:[[svc getCueModel] title]];
    
    
}


#pragma mark - Setup

- (void)addGestures{

    // gestures
    _swipeRightGesture = [[UISwipeGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(onSwipeRight:)];
    [self.swipeRightGesture setNumberOfTouchesRequired:1];
    [self.swipeRightGesture setDirection:UISwipeGestureRecognizerDirectionRight];

    [self.view addGestureRecognizer:self.swipeRightGesture];

    _swipeLeftGesture = [[UISwipeGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(onSwipeLeft:)];
    [self.swipeLeftGesture setNumberOfTouchesRequired:1];
    [self.swipeLeftGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]
                                                initWithTarget:self action:@selector(onDoubleTap:)];
    
    [doubleTapGesture setNumberOfTapsRequired:2];
    [doubleTapGesture setNumberOfTouchesRequired:1];
    
    [self.view addGestureRecognizer:doubleTapGesture];
    
    

}
-(void)removeGestures{
    
    [self.view.gestureRecognizers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.view removeGestureRecognizer:obj];
    }];

}
-(void)addObservers{
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onMotionManagerReset:)
												 name:kMotionManagerReset
											   object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onTransportBack:)
												 name:kTransportBack
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onTransportForward:)
												 name:kTransportForward
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onTransportStop:)
												 name:kTransportStop
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onTransportNext:)
												 name:kTransportNext
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onTransportCue:)
												 name:kTransportCue
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onEditModeOn:)
												 name:kEditModeOn
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onEditModeOff:)
												 name:kEditModeOff
											   object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPauseCue:)
                                                 name:kPauseCue
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onContinueCue:)
                                                 name:kContinueCue
                                               object:nil];



}
-(void)removeObservers{

    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kMotionManagerReset
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTransportForward
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTransportStop
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTransportBack
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTransportNext
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTransportCue
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kEditModeOn
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kEditModeOff
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kPauseCue
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kContinueCue
                                                  object:nil];

}

-(void)killAllCues{

    __weak SOScreensContainer *weakSelf = self;
    
    // destroy all those players
    [self.screenViewControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [obj killWithcompletionBlock:^{
            [weakSelf.screenViewControllers removeObjectForKey:key];
        }];
    }];
    
    // kill any future cues
    [self.currentBeaconModel.cues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        __block SOCueModel *cueModel = [weakSelf.modelStore cueModelWithTitle:obj];
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf
                                                 selector:@selector(playCue:)
                                                   object:cueModel];
    }];
    
}

-(void)pauseAllCues{

    [self.screenViewControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        SOScreenViewController *svc = (SOScreenViewController*)obj;
        [svc pause];
    }];
    
}

-(void)playAllCues{
    
    [self.screenViewControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [(SOScreenViewController*)obj play];
    }];

}

#pragma mark - Gestures & Notifications

-(void)onPauseCue:(NSNotification *)notification{
    
    
    [self.view bringSubviewToFront:self.pauseViewController.view];
//    [self.view bringSubviewToFront:self.touchView];
    
    [UIView animateWithDuration:0.3
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.pauseViewController.view setTransform:CGAffineTransformMakeTranslation(0.0, 0.0)];
                     }
                     completion:^(BOOL finished){
                     }
     ];

    
    [self killAllCues];
}

-(void)onContinueCue:(NSNotification *)notification{
    
    // re-start where we are
    [self triggerBeacon:self.currentBeaconModel];
//    [self.view bringSubviewToFront:self.touchView];
   
    [UIView animateWithDuration:0.3
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.pauseViewController.view setTransform:CGAffineTransformMakeTranslation(-self.view.bounds.size.width, 0.0)];
                     }
                     completion:^(BOOL finished){
                     }
     ];
    
}

-(void)onEditModeOff:(NSNotification *)notification{

    [self playAllCues];
    [self addDisplayLink];
}
-(void)onEditModeOn:(NSNotification *)notification{

    DLog(@"");
    
    [self removeDisplayLink];
    
    [self pauseAllCues];
    
    SOPropertiesViewController *props = [[SOPropertiesViewController alloc] initWithNibName:@"SOPropertiesViewController" bundle:nil];
    
    [props setCueModel:self.selectedCueModel];
    
    [self.view addSubview:props.view];
    
    [self addChildViewController:props];
    props.view.transform = CGAffineTransformMakeTranslation(0.0, 320.0);
    
    [UIView animateWithDuration:0.3
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         props.view.transform = CGAffineTransformMakeTranslation(0.0, 0.0);
                     }
                     completion:nil];
    

}

- (void)onDoubleTap:(UIGestureRecognizer *)gestureRecognizer{
        
    [[NSNotificationCenter defaultCenter] postNotificationName:kPauseCue object:nil];
    
    [self killAllCues];
    
    [self cleanup];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}
- (void)onSwipeLeft:(UIGestureRecognizer *)gestureRecognizer{

    DLog(@"");
    [[NSNotificationCenter defaultCenter] postNotificationName:kContinueCue object:nil];

    [self.view addGestureRecognizer:self.swipeRightGesture];
    [self.view removeGestureRecognizer:self.swipeLeftGesture];

}
- (void)onSwipeRight:(UIGestureRecognizer *)gestureRecognizer{
    
    DLog(@"");
    [[NSNotificationCenter defaultCenter] postNotificationName:kPauseCue object:nil];
    
    [self.view addGestureRecognizer:self.swipeLeftGesture];
    [self.view removeGestureRecognizer:self.swipeRightGesture];
    
}

-(void)onMotionManagerReset:(NSNotification *)notification{
    [[SOMotionManager sharedManager] reset];
}

-(void)onTransportStop:(NSNotification *)notification{
    
    __block int count = 0;
    
    [self.screenViewControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {

        [obj stopWithcompletionBlock:^{
           
            count++;
            
            if(count == self.screenViewControllers.count){
                // last one
                
                [self cleanup];
                [self.navigationController popViewControllerAnimated:NO];
                
            }
        }];
    }];
}

-(void)onTransportNext:(NSNotification *)notification{

    NSNumber *minor = [NSNumber numberWithInt:self.currentBeaconModel.minor + 1];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportCue object:minor];
    
}

-(void)onTransportCue:(NSNotification *)notification{

    NSNumber *minor = (NSNumber*)[notification object];
    
    // stupid hack for skipping a cue
    if([minor intValue] == 7){
        minor = [NSNumber numberWithInt:8];
    }
    
    SOBeaconModel *beaconModel = [self.modelStore beaconModelWithMinor:[minor intValue]];
    
    // kill all running cues
    [self.currentBeaconModel.cues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        __block SOCueModel *cueModel = [self.modelStore cueModelWithTitle:obj];
        [[self.screenViewControllers objectForKey:cueModel.title] stopWithcompletionBlock:^{
            DLog(@"killing : %@",cueModel.title);
            [self.screenViewControllers removeObjectForKey:cueModel.title];
        }];
    }];
    [self triggerBeacon:[self.modelStore beaconModelWithMinor:beaconModel.minor]];
    
}

-(void)onTransportForward:(NSNotification *)notification{
    [self.screenViewControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [(SOScreenViewController*)obj jumpForward:5.0f];
    }];
}
-(void)onTransportBack:(NSNotification *)notification{
    [self.screenViewControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [(SOScreenViewController*)obj jumpBack:5.0f];
    }];
}

#pragma mark - Orientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return NO;
}

- (BOOL)shouldAutorotate{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    //[[NSNotificationCenter defaultCenter] postNotificationName:kMotionManagerReset object:nil];
}
#pragma mark - Motion Refresher

- (void)onDisplayLink:(id)sender {
    
    float roll = [[SOMotionManager sharedManager] valueForKey:@"roll"];
    float yawf = [[SOMotionManager sharedManager] valueForKey:@"yaw"];

//    float pitch = [[SOMotionManager sharedManager] valueForKey:@"pitch"];
//    float heading = [[SOMotionManager sharedManager] valueForKey:@"heading"];

    [self.transport updateAttitudeWithRoll:roll andYaw:yawf];
    
    // hack for picking a current svc by where it's scrollview is positioned
    float threshold = 100.0f;
    self.selectedCueModel = nil;

    if([[NSUserDefaults standardUserDefaults] boolForKey:kLastEditState]){

        [self.screenViewControllers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            SOScreenViewController *svc = (SOScreenViewController*)obj;
            
            
            // don't test for audio cues
            if(![[[svc getCueModel] type] isEqualToString:@"audio"]){
            
                CGRect vr = [svc visibleFrame];
                
                if(vr.origin.x <= threshold && vr.origin.x >= -threshold){
                    [svc setViewIsSelected:YES];
                    self.selectedCueModel = [svc getCueModel];
                }else{
                    [svc setViewIsSelected:NO];
                }
            }
        
        }];
        
        if(self.selectedCueModel != nil){
            [[_transport selectedLabel] setText:[self.selectedCueModel title]];
            [[_transport editButton] setEnabled:YES];
        }else{
            [[_transport selectedLabel] setText:@"-"];
            [[_transport editButton] setEnabled:NO];
        }        
    }
}


@end

