//
//  FZISMeasurementTool.m
//  FZISUtils
//
//  Created by fzis299 on 16/1/14.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import "FZISMeasurementTool.h"
#import "FZISMapView.h"

@implementation FZISMeasurementTool

- (FZISMeasurementTool *)initWithMapView:(FZISMapView *)mapView
{
    self = [super init];
    if (self) {
        _mapView = mapView;
        _mapView.callout.color = [UIColor colorWithWhite:0.8 alpha:0.8];
        _mapView.callout.borderColor = [UIColor clearColor];
        _mapView.callout.delegate = self;
//        _geoBuilder = [[FZISGeoBuilder alloc] initWithMapView:mapView];
//        _geoBuilder.delegate = self;
//        _geoBuilder.enableModification = NO;
        
//        _measurementPoints = [[NSMutableArray alloc] init];
//        _tmpGraphics = [[NSMutableArray alloc] init];
//        _btnCleanup = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
//        
//        _btnCleanup.backgroundColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:0.6];
        
//        [_btnCleanup setTitle:@"X" forState:UIControlStateNormal];
//        [_btnCleanup setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        [_btnCleanup addTarget:self action:@selector(btnCleanupClicked:) forControlEvents:UIControlEventTouchUpInside];
        
//        [mapView addSubview:_btnCleanup];
    }
    return self;
}

- (void)startDistanceMeasurement
{
//    [self cleanup];
    _measurementType = measureDistance;
    [_mapView.geoBuilder startBuildingPolyline];
}

- (void)startAreaMeasurement
{
//    [self cleanup];
    _measurementType = measureArea;
    [_mapView.geoBuilder startBuildingPolygon];
}

- (void)updateWithScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint
{
    [_mapView.geoBuilder updateWithScreenPoint:screenPoint mapPoint:mapPoint];
}

- (void)FZISGeoBuilder:(FZISGeoBuilder *)builder didUpdatedGeometry:(AGSGeometry *)geometry withPoints:(NSArray *)points {
    [self showMeasurementResult4Geometry:geometry withPoints:points];
}

- (void)FZISGeoBuilder:(FZISGeoBuilder *)builder didFinishBuildingGeometry:(AGSGeometry *)geometry withPoints:(NSArray *)points {
    [self showMeasurementResult4Geometry:geometry withPoints:points];
}

- (void)showMeasurementResult4Geometry:(AGSGeometry *)geometry withPoints:(NSArray *)points {
    NSString *content = @"";
    NSString *title = @"";
    
//    NSLog(@"%ld", geometry.spatialReference.WKID);
    if (_measurementType == measureDistance) {
        title = @"距离";
        if (geometry != nil) {
            
            double totalDistance = _mapView.spatialReference.projected? fabs([AGSGeometryEngine lengthOfGeometry:geometry]) : fabs([AGSGeometryEngine geodeticLengthOfGeometry:geometry lengthUnit:[AGSLinearUnit meters] curveType:AGSGeodeticCurveTypeGeodesic]);
            if (totalDistance > 1000.0f) {
                totalDistance = totalDistance / 1000.0f;
                content = [NSString stringWithFormat:@"%0.2f公里", totalDistance];
            }
            else
            {
                content = [NSString stringWithFormat:@"%0.2f米", totalDistance];
            }
        } else {
            content = @"0米";
        }
    } else {
        title = @"面积";
        if (geometry != nil) {
            double area = _mapView.spatialReference.projected? fabs([AGSGeometryEngine areaOfGeometry:geometry]) : fabs([AGSGeometryEngine geodeticAreaOfGeometry:geometry areaUnit:[AGSAreaUnit squareMeters] curveType:AGSGeodeticCurveTypeGeodesic]);
            double areaInMu = area * 3.0 / 2000.0;
            if (area > 1000000.0) {
                area = area / 1000000.0f;
                content = [NSString stringWithFormat:@"%0.2f平方公里", area];
            }
            else
            {
                content = [NSString stringWithFormat:@"%0.2f平方米", area];
            }
            content = [NSString stringWithFormat:@"%@, 合%0.2f亩", content, areaInMu];
        } else {
            content = @"0平方米";
        }
    }
    
    _mapView.callout.title = title;
    _mapView.callout.detail = content;
    _mapView.callout.accessoryButtonImage = [self getCloseBtnImage];
    [_mapView.callout showCalloutAt:[points lastObject] screenOffset:CGPointMake(0.0, 0.0) rotateOffsetWithMap:NO animated:YES];
}
/* - (void)measureDistance
{
    [_mapView.graphicsOverlays[0].graphics removeAllObjects];//清除旧的
    
    AGSPoint *lastPoint = [_measurementPoints lastObject];
    
    NSString *distanceDisplay = @"";
    
    NSMutableArray *pointGraphics = [[NSMutableArray alloc] init];
    
    NSInteger pointCount = [_measurementPoints count];
    
    if (pointCount >= 2) {
        AGSPolylineBuilder *lineBuilder = [[AGSPolylineBuilder alloc] initWithSpatialReference:_mapView.spatialReference];
        for (NSInteger i = pointCount - 1; i >= 0; i--) {
            AGSPoint *point = [_measurementPoints objectAtIndex:i];
            [lineBuilder addPoint:point];
            if (i == pointCount - 1) {
                [pointGraphics addObject:[self getGraphic4UnfixedPoint:point]];
            } else {
                if (i % 2 == 0) {
                    [pointGraphics addObject:[self getGraphic4FixedPoint:point]];
                } else {
                    [pointGraphics addObject:[self getGraphic4MidPoint:point]];
                }
            }
        }
        
        AGSGeometry *line = [AGSGeometryEngine simplifyGeometry:[lineBuilder toGeometry]];
        AGSGraphic *lineGraphic = [self getGraphic4Polyline:line];
        [_mapView.graphicsOverlays[0].graphics addObject:lineGraphic];
        
        double totalDistance = fabs([AGSGeometryEngine lengthOfGeometry:line]);
        if (totalDistance > 1000.0f) {
            totalDistance = totalDistance / 1000.0f;
            distanceDisplay = [NSString stringWithFormat:@"%0.2f公里", totalDistance];
        }
        else
        {
            distanceDisplay = [NSString stringWithFormat:@"%0.2f米", totalDistance];
        }
        
    }
    else
    {
        [pointGraphics addObject:[self getGraphic4UnfixedPoint:lastPoint]];
        distanceDisplay = @"0米";
    }
    [_mapView.graphicsOverlays[0].graphics addObjectsFromArray:pointGraphics];
    _mapView.callout.title = @"距离";
    _mapView.callout.detail = distanceDisplay;
    _mapView.callout.accessoryButtonImage = [self getCloseBtnImage];
    [_mapView.callout showCalloutAt:lastPoint screenOffset:CGPointMake(0.0, 0.0) rotateOffsetWithMap:NO animated:YES];
}


- (void)measureArea
{
    [_mapView.graphicsOverlays[0].graphics removeAllObjects];//清除旧的
    
    AGSPoint *lastPoint = [_measurementPoints lastObject];
    
    NSString *areaDisplay = @"";
    
    NSMutableArray *pointGraphics = [[NSMutableArray alloc] init];
    
    NSInteger pointCount = _measurementPoints.count;
    if (pointCount >= 3) {
        AGSPolygonBuilder *polygonBuilder = [AGSPolygonBuilder polygonBuilderWithSpatialReference:_mapView.spatialReference];
        for (int i = 0; i < pointCount; i++) {
            AGSPoint *point = [_measurementPoints objectAtIndex:i];
            [polygonBuilder addPoint:point];
            if (i == pointCount - 1) {
                [pointGraphics addObject:[self getGraphic4UnfixedPoint:point]];
            } else {
                [pointGraphics addObject:[self getGraphic4FixedPoint:point]];
            }
        }
        
        AGSGeometry *polygon = [AGSGeometryEngine simplifyGeometry:[polygonBuilder toGeometry]];
        
        AGSGraphic *polygonGraphic = [self getGraphic4Polygon:polygon];
        [_mapView.graphicsOverlays[0].graphics addObject:polygonGraphic];
        
        double area = fabs([AGSGeometryEngine areaOfGeometry:polygon]);
        double areaInMu = area * 3.0 / 2000.0;
        if (area > 1000000.0) {
            area = area / 1000000.0f;
            areaDisplay = [NSString stringWithFormat:@"%0.2f平方公里", area];
        }
        else
        {
            areaDisplay = [NSString stringWithFormat:@"%0.2f平方米", area];
        }
        areaDisplay = [NSString stringWithFormat:@"%@, 合%0.2f亩", areaDisplay, areaInMu];
        
    }
    else
    {
        for (int i = 0; i < pointCount; i++) {
            AGSPoint *point = [_measurementPoints objectAtIndex:i];
            if (i == pointCount - 1) {
                [pointGraphics addObject:[self getGraphic4UnfixedPoint:point]];
            } else {
                [pointGraphics addObject:[self getGraphic4FixedPoint:point]];
            }
        }
        areaDisplay = @"0平方米";
    }
    [_mapView.graphicsOverlays[0].graphics addObjectsFromArray:pointGraphics];
    _mapView.callout.title = @"面积";
    _mapView.callout.detail = areaDisplay;
    _mapView.callout.accessoryButtonImage = [self getCloseBtnImage];
    [_mapView.callout showCalloutAt:lastPoint screenOffset:CGPointMake(0.0, 0.0) rotateOffsetWithMap:NO animated:YES];
} */

- (void)stopMeasurement
{
    [_mapView.geoBuilder stopBuildingGeometry];
}

- (void)cleanup
{
    [_mapView.geoBuilder cleanup];
    [_mapView.callout dismiss];
    
    
//    _btnCleanup.frame = CGRectMake(0, 0, 0, 0);
}

//- (void)updatePosition {
//    if ([_measurementPoints count] > 0) {
//        AGSPoint *lastPoint = [_measurementPoints lastObject];
//        CGPoint lastScreenPoint = [_mapView locationToScreen:lastPoint];
//        CGPoint btnCleanupOrigPoint = CGPointMake(lastScreenPoint.x - 15.0, lastScreenPoint.y - 40.0);
//        _btnCleanup.frame = CGRectMake(btnCleanupOrigPoint.x, btnCleanupOrigPoint.y, 30, 30);
//        
//        AGSPoint *txtPoint = [_mapView screenToLocation:CGPointMake(lastScreenPoint.x, lastScreenPoint.y + 20.0)];
//        
//        if (_measurementType == measureDistance) {
//            
//            if ([_measurementPoints count] >= 1) {
//                _lastLabelGraphic.geometry = txtPoint;
//            }
//        }
//        else
//        {
//            if ([_measurementPoints count] >= 3) {
//                _lastLabelGraphic.geometry = txtPoint;
//            }
//        }
//    }
//}

- (UIImage *)getCloseBtnImage {
    UIGraphicsBeginImageContext(CGSizeMake(40.0, 40.0));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 10.0, 10.0);
    CGContextAddLineToPoint(context, 30.0, 30.0);
    CGContextMoveToPoint(context, 30.0, 10.0);
    CGContextAddLineToPoint(context, 10.0, 30.0);
    CGContextStrokePath(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)didTapAccessoryButtonForCallout:(AGSCallout *)callout {
    [self cleanup];
}

//- (AGSGraphic *)getGraphic4Text:(NSString *)text onPoint:(AGSGeometry *)geometry {
//    AGSTextSymbol *txtSymbol = [AGSTextSymbol textSymbolWithText:text color:[UIColor purpleColor] size:15.0 horizontalAlignment:AGSHorizontalAlignmentCenter verticalAlignment:AGSVerticalAlignmentMiddle];
//    txtSymbol.fontFamily = @"Heiti SC";
//    txtSymbol.haloWidth = 1.0;
//    txtSymbol.haloColor = [UIColor colorWithWhite:0.5 alpha:0.8];
//    AGSPoint *point = (AGSPoint *)geometry;
//    CGPoint screenPoint = [_mapView locationToScreen:point];
//    AGSPoint *txtPoint = [_mapView screenToLocation:CGPointMake(screenPoint.x, screenPoint.y + 20.0)];
//    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:txtPoint symbol:txtSymbol attributes:nil];
//    return graphic;
//}

@end
