//
//  FZISLineView.h
//  FZISUtils
//
//  Created by fzis299 on 16/1/26.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    shapeRectangle = 0,
    shapeRectangleFill,
    shapeCircle,
    shapeCircleFill,
    shapeFreeLine
}FZISShapeType;

@protocol FZISLineViewDelegate;
@protocol FZISLineViewTouchDelegate;

@interface FZISLineView : UIView{
    UIImage *_currentImg;
//    UILongPressGestureRecognizer *_longPressGestureRecognizer;
}

@property(nonatomic,strong) NSMutableArray *points;
@property(nonatomic,strong) UIImageView *imageView;

@property (nonatomic, retain) UIColor *penColor;
@property (nonatomic, assign) FZISShapeType penShape;
@property (nonatomic, assign) float penWidth;

@property (nonatomic, weak) id<FZISLineViewDelegate> lineViewDelegate;
@property (nonatomic, weak) id<FZISLineViewTouchDelegate> lineViewTouchDelegate;

@end


@protocol FZISLineViewDelegate <NSObject>

@optional

- (void)lineViewTouchesBegan:(FZISLineView *)lineView;
- (void)lineViewTouchesEnded:(FZISLineView *)lineView;

@end

@protocol FZISLineViewTouchDelegate <NSObject>

@optional

- (void)lineViewLongPressReceived:(CGPoint)point;
- (void)lineViewSingleTapReceived:(CGPoint)point;

@end
