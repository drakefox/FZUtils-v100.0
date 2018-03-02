//
//  FZISSandboxTool.h
//  FZISUtils
//
//  Created by fzis299 on 16/1/15.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FZISMapView.h"
#import "FZISLineView.h"

@interface FZISSandboxTool : NSObject
<FZISLineViewDelegate,CALayerDelegate>
{
    __weak FZISMapView *_mapView;
    BOOL _isImageSaved;
    FZISLineView *_lineView;
}

//@property (nonatomic, retain) FZISLineView *lineView;
@property (nonatomic, retain) UIColor *penColor;
@property (nonatomic, assign) FZISShapeType penShape;
@property (nonatomic, assign) float penWidth;
@property (nonatomic, assign) float penAlpha;

@property (nonatomic, assign) BOOL imageSaved;

- (FZISSandboxTool *)initWithMapView:(FZISMapView *)mapView;
- (void)startDrawing;
//- (void)stopDrawing;
//- (UIImage *)saveDrawnImage;
- (void)cleanup;
- (void)quit;
- (FZISLineView *)lineView;

@end
