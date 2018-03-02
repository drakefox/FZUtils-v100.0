//
//  FZISLineView.m
//  FZISUtils
//
//  Created by fzis299 on 16/1/26.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import "FZISLineView.h"

@implementation FZISLineView

@synthesize points,imageView,lineViewDelegate,lineViewTouchDelegate;
@synthesize penColor,penShape,penWidth;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //添加UIImageView
        imageView = [[UIImageView alloc] initWithFrame:self.frame];
        [self addSubview:imageView];
        self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0];
        
        self.penColor = [UIColor redColor];
        self.penWidth = 1.0;
        self.penShape = shapeFreeLine;
        
        points = [[NSMutableArray alloc] init];
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressReceived:)];
        [self addGestureRecognizer:longPressGestureRecognizer];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapReceived:)];
        
        [self addGestureRecognizer:tapGestureRecognizer];
        
    }
    return self;
}

- (void)longPressReceived:(UIGestureRecognizer *)gestureRecognizer {
    imageView.image = nil;
    [points removeAllObjects];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"long press");
        CGPoint screenPoint = [gestureRecognizer locationInView:self];
        if (lineViewTouchDelegate != nil && [lineViewTouchDelegate respondsToSelector:@selector(lineViewLongPressReceived:)]) {
            [lineViewTouchDelegate lineViewLongPressReceived:screenPoint];
        }
    }
}

- (void)singleTapReceived:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"tap");
    imageView.image = nil;
    [points removeAllObjects];
    CGPoint screenPoint = [gestureRecognizer locationInView:self];
    if (lineViewTouchDelegate != nil && [lineViewTouchDelegate respondsToSelector:@selector(lineViewSingleTapReceived:)]) {
        [lineViewTouchDelegate lineViewSingleTapReceived:screenPoint];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"touch");
    
    if (lineViewDelegate != nil && [lineViewDelegate respondsToSelector:@selector(lineViewTouchesBegan:)]) {
        [lineViewDelegate lineViewTouchesBegan:self];
    }
    
    //手指按下时开始创建画布
    UIGraphicsBeginImageContext(imageView.frame.size);
    //[imageView.image drawInRect:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    //    imageView.alpha = 1.0;
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    [points addObject:[NSValue value:&location withObjCType:@encode(CGPoint)]];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    //手指移动时记录上一次的点坐标和当前点坐标
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    CGPoint pastLocation = [touch previousLocationInView:self];
    
    [points addObject:[NSValue value:&location withObjCType:@encode(CGPoint)]];
    //NSLog(@"touchesMove : %f, %f,count=%d\n", location.x, location.y,points.count);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, self.penWidth);
    CGContextSetStrokeColorWithColor(context, self.penColor.CGColor);
    if (self.penShape == shapeFreeLine) {
        //开始画线和渲染
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, pastLocation.x, pastLocation.y);
        CGContextAddLineToPoint(context, location.x, location.y);
        CGContextStrokePath(context);
    }
    else if (self.penShape == shapeCircle || self.penShape == shapeCircleFill)
    {
        CGPoint startPoint = [points.firstObject CGPointValue];
        CGRect rectToFill = CGRectMake(startPoint.x, startPoint.y, location.x - startPoint.x, location.y - startPoint.y);
        CGContextClearRect(context, self.frame);
        if (self.penShape == shapeCircleFill) {
            CGContextSetFillColorWithColor(context, self.penColor.CGColor);
            CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(), rectToFill);
            
        } else {
            CGContextSetStrokeColorWithColor(context, self.penColor.CGColor);
            CGContextSetLineWidth(context, self.penWidth);
            CGContextStrokeEllipseInRect(UIGraphicsGetCurrentContext(), rectToFill);
        }
    }
    else
    {
        CGPoint startPoint = [points.firstObject CGPointValue];
        CGRect rectToFill = CGRectMake(startPoint.x, startPoint.y, location.x - startPoint.x, location.y - startPoint.y);
        CGContextClearRect(context, self.frame);
        if (self.penShape == shapeRectangleFill) {
            CGContextSetFillColorWithColor(context, self.penColor.CGColor);
            CGContextFillRect(UIGraphicsGetCurrentContext(), rectToFill);
            
        } else {
            CGContextSetStrokeColorWithColor(context, self.penColor.CGColor);
            CGContextSetLineWidth(context, self.penWidth);
            CGContextStrokeRect(UIGraphicsGetCurrentContext(), rectToFill);
        }
    }
    
    imageView.image = UIGraphicsGetImageFromCurrentImageContext();
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"touch end");
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, self.frame);
    imageView.image = nil;
    
    //    imageView.alpha = 0.0;
    
    UIGraphicsEndImageContext();//松手时移除画布
    
    if ([points count] > 1 && lineViewDelegate != nil && [lineViewDelegate respondsToSelector:@selector(lineViewTouchesEnded:)]) {
        [lineViewDelegate lineViewTouchesEnded:self];
    }
    //    [self removeFromSuperview];
    [points removeAllObjects];
}

- (UIImage *)addTwoImageToOne:(UIImage *)oneImg twoImage:(UIImage *)twoImg
{
    UIGraphicsBeginImageContext(oneImg.size);
    
    [oneImg drawInRect:CGRectMake(0, 0, oneImg.size.width, oneImg.size.height)];
    [twoImg drawInRect:CGRectMake(0, 0, twoImg.size.width, twoImg.size.height)];
    
    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resultImg;
}


@end
