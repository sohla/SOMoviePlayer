//
//  SOCueStore.m
//  SOMoviePlayer
//
//  Created by Stephen OHara on 31/05/2014.
//  Copyright (c) 2014 Stephen OHara. All rights reserved.
//

#import "SOModelStore.h"

#define kLastFileSaved @"kLastFileSaved"
#define kBGQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface SOModelStore ()


@property (assign, nonatomic)   SOCueModel *currentCueModel;

@end

@implementation SOModelStore


- (instancetype)init{

    self = [super init];
    if (self) {

        [self loadCues];
    }
    return self;
}

-(void)loadCues{

    
    if(![[NSUserDefaults standardUserDefaults] stringForKey:kLastFileSaved] ) {
        
        DLog(@"Loading default data file...");
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
        [self loadJSONCuesWithPath:path completionBlock:^(NSError *error) {
            
            if(error){
                NSLog(@"%@",error.localizedDescription);
            }else{
                
                [self saveLatest];

            }
        }];
        
        
        

    }else{
    
        NSString *latestFile = [[NSUserDefaults standardUserDefaults] stringForKey:kLastFileSaved];
        NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [docsDirectory stringByAppendingPathComponent:latestFile];
        
        DLog(@"Loading %@",latestFile);

        [self loadJSONCuesWithPath:path completionBlock:^(NSError *error) {
            
            if(error){
                NSLog(@"%@",error.localizedDescription);
            }
        }];
        
    }

}

-(void)loadJSONCuesWithPath:(NSString*)path completionBlock:(void (^)(NSError *error)) block{
    
    NSURL *url = [NSURL fileURLWithPath:path];
    if(url == nil){
        
        NSError *err = [NSError errorWithDomain:@"fileURLWithPath"
                                           code:1
                                         userInfo:[NSDictionary dictionaryWithObject:@"Could not find file at path"
                                                                              forKey:NSLocalizedDescriptionKey]];

        block(err);
    }
    
    
    dispatch_async(kBGQueue, ^{
        
        __block NSError *err;
        __block NSData* data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&err];
        
        if(err){
            block(err);
        }else{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                

                _sessionModel = [[SOSessionModel alloc] initWithData:data error:&err];
                self.currentCueModel = self.sessionModel.cues[0];

                block(nil);

            });
        }
        
    });
}

-(void)saveLatest{
    
    NSDate	*now = [NSDate date];
	NSCalendar *currentCalendar = [NSCalendar currentCalendar];
	NSDateComponents *comp = [currentCalendar components:
							  (NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|
							   NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit)
												fromDate:now];
    
    
	// form string for file name using current date to form unique file name
    NSString* newFileName = [[NSString stringWithFormat:
                              @"%@_%d%d%d_%d%d%d",
                              @"data",
                              [comp year],[comp month],[comp day],
                              [comp hour],[comp minute],[comp second]] stringByAppendingPathExtension:@"json"];
    
    [self saveCuesAsJsonWithTitle:newFileName];
    
    [[NSUserDefaults standardUserDefaults] setObject:newFileName forKey:kLastFileSaved];
    [[NSUserDefaults standardUserDefaults] synchronize];


}

-(void)saveCuesAsJsonWithTitle:(NSString*)title{
    
    DLog(@"Saving %@",title);

    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName = [NSString stringWithFormat:@"%@",title];
    NSString *path = [docsDirectory stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil]) {
        //        NSError *error = [NSError errorWithDomain:@"writeToFile"
        //                                             code:1
        //                                         userInfo:[NSDictionary dictionaryWithObject:@"Can't create file" forKey:NSLocalizedDescriptionKey]
        //                          ];
        //        NSAssert(error==noErr,@"Can't create file");
    }
    
    
    NSString *jsonString = [self.sessionModel toJSONString];
    [jsonString writeToFile:path atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];

}

-(SOCueModel*)cueModelAtIndex:(int)index{
    return self.sessionModel.cues[index];
}
@end
