//
//  CrossMarkView.m
//  FZISUtils
//
//  Created by fzis299 on 2017/7/19.
//  Copyright © 2017年 FZIS. All rights reserved.
//

#import "CrossMarkView.h"

@implementation CrossMarkView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (CrossMarkView *)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    UIGraphicsPushContext(ctx);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetRGBStrokeColor(ctx, 50.0/255.0, 79.0/255.0, 133.0/255.0, 0.8);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 400.0, self.frame.size.height / 2.0);
    CGContextAddLineToPoint(ctx, self.frame.size.width - 400.0, self.frame.size.height / 2.0);
    CGContextStrokePath(ctx);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, self.frame.size.width / 2.0, 300.0);
    CGContextAddLineToPoint(ctx, self.frame.size.width / 2.0, self.frame.size.height - 300.0);
    CGContextStrokePath(ctx);
    CGRect rectangle = CGRectMake(self.frame.size.width / 2.0 - 50.0, self.frame.size.height / 2.0 - 50.0, 100.0, 100.0);
    CGContextAddEllipseInRect(ctx, rectangle);
    CGContextStrokePath(ctx);
    UIGraphicsPopContext();
}

@end
