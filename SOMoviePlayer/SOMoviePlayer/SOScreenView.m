//
//  SOScreenView.m
//  SOMoviePlayer
//
//  Created by Stephen OHara on 10/05/2014.
//  Copyright (c) 2014 Stephen OHara. All rights reserved.
//

#import "SOScreenView.h"


@interface SOScreenView ()


-(UIColor*)randomColor;

@end


@implementation SOScreenView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [self randomColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect{
    
    CGContextRef    context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 3.0f);
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);

    CGPoint topLeft = {0.0f, 0.0f};
    CGPoint bottomRight = {self.bounds.size.width, self.bounds.size.height};
    
    CGContextMoveToPoint(context, topLeft.x, topLeft.y);
    CGContextAddLineToPoint(context, bottomRight.x, bottomRight.y);
    
    CGContextMoveToPoint(context, topLeft.x, bottomRight.y);
    CGContextAddLineToPoint(context, bottomRight.x, topLeft.y);
    
    CGContextStrokePath(context);

}

-(UIColor*)randomColor{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0f];
}

@end