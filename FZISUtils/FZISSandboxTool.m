//
//  FZISSandboxTool.m
//  FZISUtils
//
//  Created by fzis299 on 16/1/15.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import "FZISSandboxTool.h"

#define kSampleAmount 1000.0

@implementation FZISSandboxTool

@synthesize penColor, penShape, penAlpha, penWidth;
@synthesize imageSaved = _isImageSaved;

- (FZISSandboxTool *)initWithMapView:(FZISMapView *)mapView
{
    self = [super init];
    if (self) {
        _mapView = mapView;
        
        penColor = [UIColor redColor];
        penShape = shapeFreeLine;
        penAlpha = 1.0;
        penWidth = 2.0;
        
        
        
        _isImageSaved = YES;
    }    
    
    return self;
}

- (FZISLineView *)lineView {
    return _lineView;
}

- (void)startDrawing
{
    [self addLineView];
//    [self addDrawLayer];
}

- (void)addLineView
{
    if (!_lineView) {
        _lineView = [[FZISLineView alloc] initWithFrame:_mapView.bounds];
    }
    _lineView.penColor = self.penColor;
    _lineView.penWidth = self.penWidth;
    _lineView.penShape = self.penShape;
    _lineView.lineViewDelegate = self;
    [_mapView addSubview:_lineView];
}

#pragma mark - FZIS_lineView delegate functions

- (void)lineViewTouchesEnded: (FZISLineView *)lineView
{
    _isImageSaved = NO;
    
    switch (self.penShape) {
        case shapeFreeLine:
            [self addFreeLineGraphic];
            break;
        case shapeCircle: case shapeCircleFill:
            [self addCircleGraphic:self.penShape];
            break;
        case shapeRectangle: case shapeRectangleFill:
            [self addRetangleGraphic:self.penShape];
            break;
        default:
            break;
    }
    
    
    [lineView.points removeAllObjects];
}

- (void)addFreeLineGraphic {
    AGSPolylineBuilder *lineBuilder = [AGSPolylineBuilder polylineBuilderWithSpatialReference:_mapView.spatialReference];
    NSMutableArray *points = _lineView.points;
    for (int i = 0; i < [points count]; i++)
    {
        CGPoint screenPoint = [[points objectAtIndex:i] CGPointValue];
        
        AGSPoint *mapPoint = [_mapView screenToLocation:screenPoint];//屏幕坐标转地图坐标
        [lineBuilder addPoint:mapPoint];
    }
    
    AGSSimpleLineSymbol *lineSymbol = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:self.penColor width:self.penWidth];
    AGSGraphic * drawGraphic= [AGSGraphic graphicWithGeometry:[lineBuilder toGeometry] symbol:lineSymbol attributes:nil];
    [_mapView.graphicsOverlays[0].graphics addObject:drawGraphic];
}

- (void)addCircleGraphic: (FZISShapeType)type {
    CGPoint startPoint = [_lineView.points.firstObject CGPointValue];
    CGPoint endPoint = [_lineView.points.lastObject CGPointValue];
    
    AGSPoint *msPoint = [_mapView screenToLocation:startPoint];
    AGSPoint *mePoint = [_mapView screenToLocation:endPoint];
    AGSPoint *mCenter = AGSPointMake((msPoint.x + mePoint.x) / 2.0, (msPoint.y + mePoint.y) / 2.0, _mapView.spatialReference);
    
    double width = (mePoint.x - msPoint.x) / 2.0;
    double height = (mePoint.y - msPoint.y) / 2.0;
    
    NSMutableArray *yOff = [[NSMutableArray alloc] init];
    
    double step = width / kSampleAmount;
    
    for (int i = -kSampleAmount; i <= kSampleAmount; i++) {
        double x = i * step;
        double y = sqrt((height * height * width * width - height * height * x * x) / (width * width));
        [yOff addObject:[NSNumber numberWithDouble:y]];
    }
    AGSPolygonBuilder *polygonBuilder = [AGSPolygonBuilder polygonBuilderWithSpatialReference:_mapView.spatialReference];
    for (int j = -kSampleAmount; j <= kSampleAmount; j++) {
        AGSPoint *point = AGSPointMake(mCenter.x + j * step, mCenter.y - [[yOff objectAtIndex:j + kSampleAmount] doubleValue], _mapView.spatialReference);
        [polygonBuilder addPoint:point];
    }
    for (int k = kSampleAmount - 1; k >= -kSampleAmount + 1; k--) {
        AGSPoint *point = AGSPointMake(mCenter.x + k * step, mCenter.y + [[yOff objectAtIndex:k + kSampleAmount] doubleValue], _mapView.spatialReference);
        [polygonBuilder addPoint:point];
    }
    UIColor *olColor = (type == shapeCircle)? penColor : [UIColor clearColor];
    UIColor *fillColor = (type == shapeCircle)? [UIColor clearColor] : penColor;
    
    AGSSimpleLineSymbol *lineSymbol = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:olColor width:self.penWidth];
    AGSSimpleFillSymbol *symbol = [AGSSimpleFillSymbol simpleFillSymbolWithStyle:AGSSimpleFillSymbolStyleSolid color:fillColor outline:lineSymbol];
    AGSGraphic * drawGraphic= [AGSGraphic graphicWithGeometry:[polygonBuilder toGeometry] symbol:symbol attributes:nil];
    [_mapView.graphicsOverlays[0].graphics addObject:drawGraphic];
}

- (void)addRetangleGraphic: (FZISShapeType)type {
    CGPoint startPoint = [_lineView.points.firstObject CGPointValue];
    CGPoint endPoint = [_lineView.points.lastObject CGPointValue];
    
    AGSPoint *msPoint = [_mapView screenToLocation:startPoint];
    AGSPoint *mePoint = [_mapView screenToLocation:endPoint];
    
    AGSPolygonBuilder *polygonBuilder = [AGSPolygonBuilder polygonBuilderWithSpatialReference:_mapView.spatialReference];
    
    [polygonBuilder addPoint:msPoint];
    [polygonBuilder addPoint:AGSPointMake(mePoint.x, msPoint.y, _mapView.spatialReference)];
    [polygonBuilder addPoint:mePoint];
    [polygonBuilder addPoint:AGSPointMake(msPoint.x, mePoint.y, _mapView.spatialReference)];
    
    UIColor *olColor = (type == shapeRectangle)? penColor : [UIColor clearColor];
    UIColor *fillColor = (type == shapeRectangle)? [UIColor clearColor] : penColor;
    
    AGSSimpleLineSymbol *lineSymbol = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:olColor width:self.penWidth];
    AGSSimpleFillSymbol *symbol = [AGSSimpleFillSymbol simpleFillSymbolWithStyle:AGSSimpleFillSymbolStyleSolid color:fillColor outline:lineSymbol];
    AGSGraphic * drawGraphic= [AGSGraphic graphicWithGeometry:[polygonBuilder toGeometry] symbol:symbol attributes:nil];
    [_mapView.graphicsOverlays[0].graphics addObject:drawGraphic];
}

- (void)lineViewTouchesBegan:(FZISLineView *)lineView
{
    lineView.penColor = self.penColor;
    lineView.penWidth = self.penWidth;
    lineView.penShape = self.penShape;
}

- (void)cleanup
{
    
    [_mapView.graphicsOverlays[0].graphics removeAllObjects];
    
    _isImageSaved = YES;
}

- (void)quit
{
    _isImageSaved = YES;
    [_lineView removeFromSuperview];
}

@end
