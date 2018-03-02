//
//  FZISGeoBuilder.m
//  FZISUtils
//
//  Created by fzis299 on 16/1/14.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import "FZISGeoBuilder.h"
#import "FZISMapView.h"

@implementation FZISGeoBuilder

@synthesize enableModification;


- (FZISGeoBuilder *)initWithMapView:(FZISMapView *)mapView
{
    self = [super init];
    if (self) {
        _mapView = mapView;
                
        _geoPoints = [[NSMutableArray alloc] init];
        _midPoints = [[NSMutableArray alloc] init];
        _isEditing = NO;
        _insertIndex = -1;
        enableModification = NO;
    }
    return self;
}

- (void)startBuildingPolyline
{
    [self cleanup];
    _geoType = AGSGeometryTypePolyline;
}

- (void)startBuildingPolygon
{
    [self cleanup];
    _geoType = AGSGeometryTypePolygon;
}

- (void)updateWithScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint
{
    
    if (enableModification) {
        __weak typeof(self) weakSelf = self;
        [_mapView identifyGraphicsOverlaysAtScreenPoint:screenPoint tolerance:20.0 returnPopupsOnly:NO completion:^(NSArray<AGSIdentifyGraphicsOverlayResult *> * _Nullable identifyResults, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error != nil) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: error.localizedDescription};
                NSError *myError = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:identifyOperationError userInfo:userInfo];
                if (strongSelf->_mapView.operationHandler != nil && [strongSelf->_mapView.operationHandler respondsToSelector:@selector(operationFailedWithError:)]) {
                    [strongSelf->_mapView.operationHandler operationFailedWithError:myError];
                }
            } else {
                [_mapView.graphicsOverlays[0].graphics removeAllObjects];//清除旧的
                AGSGeometry *geometry;
                AGSPoint *tapPoint = mapPoint;
                if ([identifyResults count] == 1) {
                    AGSIdentifyGraphicsOverlayResult *result = [identifyResults objectAtIndex:0];
                    for (AGSGraphic *graphic in result.graphics) {
                        if ([strongSelf->_midPoints containsObject:graphic.geometry]) {
                            _insertIndex = [_midPoints indexOfObject:graphic.geometry] + 1;
                            _isEditing = YES;
                            tapPoint = (AGSPoint *)(graphic.geometry);
                            break;
                        }
                    }
                }
                
                if (!_isEditing) {
                    geometry = [strongSelf editGeometryByAddingNewPoint:tapPoint];
                } else {
                    geometry = [strongSelf editGeometryByModifyingExistingPoint:tapPoint];
                }
                
                if (strongSelf.delegate != nil) {
                    [strongSelf.delegate FZISGeoBuilder:strongSelf didUpdatedGeometry:geometry withPoints:_geoPoints];
                }
            }
        }];
    } else {
        AGSGeometry *geometry;
        [_mapView.graphicsOverlays[0].graphics removeAllObjects];//清除旧的
        geometry = [self editGeometryByAddingNewPoint:mapPoint];
        if (self.delegate != nil) {
            [self.delegate FZISGeoBuilder:self didUpdatedGeometry:geometry withPoints:_geoPoints];
        }
    }
}

- (AGSGeometry *)editGeometryByAddingNewPoint:(AGSPoint *)point {
    AGSGeometry *geometry;
    
    if ([_geoPoints count] > 0 && enableModification) {
        AGSPoint *prePoint = [_geoPoints lastObject];
        AGSPoint *midPoint = AGSPointMake((prePoint.x + point.x) / 2.0, (prePoint.y + point.y) / 2.0, _mapView.spatialReference);
        
        
        [_midPoints addObject:midPoint];
        
        if ([_geoPoints count] > 1 && _geoType == AGSGeometryTypePolygon) {
            
            if ([_midPoints count] > 3) {
                [_midPoints removeObjectAtIndex:[_midPoints count] - 2];
            }
            
            AGSPoint *startPoint = [_geoPoints firstObject];
            AGSPoint *lastMidPoint = AGSPointMake((startPoint.x + point.x) / 2.0, (startPoint.y + point.y) / 2.0, _mapView.spatialReference);
            [_midPoints addObject:lastMidPoint];
        }
    }
    
    [_geoPoints addObject:point];
    
    if (_geoType == AGSGeometryTypePolyline) {
        geometry = [self drawPolylineWithUnfixedPoint:[_geoPoints lastObject]];
    }
    else
    {
        geometry = [self drawPolygonWithUnfixedPoint:[_geoPoints lastObject]];
    }
    
    return geometry;
}


- (AGSGeometry *)editGeometryByModifyingExistingPoint:(AGSPoint *)point {
    AGSGeometry *geometry;
    
    if (![_midPoints containsObject:point]) {
        [_geoPoints insertObject:point atIndex:_insertIndex];
        if (([_midPoints count] == 1 && _geoType != AGSGeometryTypePolygon) || [_midPoints count] > 1) {
            [_midPoints removeObjectAtIndex:_insertIndex - 1];
        }
        AGSPoint *prevPoint = [_geoPoints objectAtIndex:_insertIndex - 1];
        AGSPoint *nextPoint = (_insertIndex + 1 >= [_geoPoints count])? _geoPoints.firstObject : [_geoPoints objectAtIndex:_insertIndex + 1];
        
        AGSPoint *midPoint1 = AGSPointMake((prevPoint.x + point.x) / 2.0, (prevPoint.y + point.y) / 2.0, _mapView.spatialReference);
        AGSPoint *midPoint2 = AGSPointMake((nextPoint.x + point.x) / 2.0, (nextPoint.y + point.y) / 2.0, _mapView.spatialReference);
        [_midPoints insertObject:midPoint2 atIndex:_insertIndex - 1];
        [_midPoints insertObject:midPoint1 atIndex:_insertIndex - 1];
        
        _isEditing = NO;
        _insertIndex = -1;
    }
    
    if (_geoType == AGSGeometryTypePolyline) {
        geometry = [self drawPolylineWithUnfixedPoint:point];
    }
    else
    {
        geometry = [self drawPolygonWithUnfixedPoint:point];
    }
    return geometry;
}


- (AGSGeometry *)drawPolygonWithUnfixedPoint:(AGSPoint *)point {
    NSInteger geoPointCount = [_geoPoints count];
    AGSGeometry *polygon = nil;
    if (geoPointCount >= 3) {
        AGSPolygonBuilder *polygonBuilder = [AGSPolygonBuilder polygonBuilderWithSpatialReference:_mapView.spatialReference];
        for (int i = 0; i < geoPointCount; i++) {
            AGSPoint *point = [_geoPoints objectAtIndex:i];
            [polygonBuilder addPoint:point];
        }
        polygon = [AGSGeometryEngine simplifyGeometry:[polygonBuilder toGeometry]];
        
        AGSGraphic *polygonGraphic = [self getGraphic4Polygon:polygon];
        [_mapView.graphicsOverlays[0].graphics addObject:polygonGraphic];
        if (point != nil) {
            if ([_geoPoints containsObject:point]) {
                [self drawPointsWithUnfixedGeoPoint:point];
            } else {
                [self drawPointsWithUnfixedMidPoint:point];
            }
        } else {
            [self drawPoints];
        }
        
    } else {
        if (geoPointCount == 2) {
            [self drawPolylineWithUnfixedPoint:point];
        } else {
            if (point != nil) {
                [self drawPointsWithUnfixedGeoPoint:point];
            } else {
                [self drawPoints];
            }
        }
    }
    return polygon;
}

- (AGSGeometry *)drawPolylineWithUnfixedPoint:(AGSPoint *)point {
    NSInteger geoPointCount = [_geoPoints count];
    AGSGeometry *line = nil;
    if (geoPointCount > 1) {
        AGSPolylineBuilder *lineBuilder = [[AGSPolylineBuilder alloc] initWithSpatialReference:_mapView.spatialReference];
        for (NSInteger i = 0; i < geoPointCount; i++) {
            AGSPoint *point = [_geoPoints objectAtIndex:i];
            [lineBuilder addPoint:point];
        }
        line = [lineBuilder toGeometry];
        AGSGraphic *lineGraphic = [self getGraphic4Polyline:line];
        [_mapView.graphicsOverlays[0].graphics addObject:lineGraphic];
    }
    if (point != nil) {
        if ([_geoPoints containsObject:point]) {
            [self drawPointsWithUnfixedGeoPoint:point];
        } else {
            [self drawPointsWithUnfixedMidPoint:point];
        }
    } else {
        [self drawPoints];
    }
    
    
    return line;
}

- (void)drawPointsWithUnfixedGeoPoint:(AGSPoint *)point {
    NSInteger geoPointCount;
    NSInteger midPointCount;
    NSMutableArray *tmpGeoPoints;
    
    NSMutableArray *pointGraphics = [[NSMutableArray alloc] init];
    
    geoPointCount = [_geoPoints count] - 1;
    midPointCount = [_midPoints count];
    tmpGeoPoints = [NSMutableArray arrayWithArray:[_geoPoints copy]];
    [tmpGeoPoints removeObject:point];
    for (NSInteger i = 0; i < midPointCount; i++) {
        AGSPoint *midPoint = [_midPoints objectAtIndex:i];
        [pointGraphics addObject:[self getGraphic4MidPoint:midPoint]];
    }
    for (NSInteger j = 0; j < geoPointCount; j++) {
        AGSPoint *geoPoint = [tmpGeoPoints objectAtIndex:j];
        [pointGraphics addObject:[self getGraphic4FixedPoint:geoPoint]];
    }
    
    [pointGraphics addObject:[self getGraphic4UnfixedPoint:point]];
    
    [_mapView.graphicsOverlays[0].graphics addObjectsFromArray:pointGraphics];
}

- (void)drawPointsWithUnfixedMidPoint:(AGSPoint *)point {
    NSInteger geoPointCount;
    NSInteger midPointCount;
    NSMutableArray *tmpGeoPoints;
    
    NSMutableArray *pointGraphics = [[NSMutableArray alloc] init];
    
    geoPointCount = [_geoPoints count];
    midPointCount = [_midPoints count] - 1;
    tmpGeoPoints = [NSMutableArray arrayWithArray:[_midPoints copy]];
    [tmpGeoPoints removeObject:point];
    for (NSInteger i = 0; i < midPointCount; i++) {
        AGSPoint *midPoint = [tmpGeoPoints objectAtIndex:i];
        [pointGraphics addObject:[self getGraphic4MidPoint:midPoint]];
    }
    for (NSInteger j = 0; j < geoPointCount; j++) {
        AGSPoint *geoPoint = [_geoPoints objectAtIndex:j];
        [pointGraphics addObject:[self getGraphic4FixedPoint:geoPoint]];
    }
    [pointGraphics addObject:[self getGraphic4UnfixedPoint:point]];
    
    [_mapView.graphicsOverlays[0].graphics addObjectsFromArray:pointGraphics];
}

- (void)drawPoints {
    NSInteger geoPointCount;
    NSMutableArray *pointGraphics = [[NSMutableArray alloc] init];
    
    geoPointCount = [_geoPoints count];
    for (NSInteger j = 0; j < geoPointCount; j++) {
        AGSPoint *geoPoint = [_geoPoints objectAtIndex:j];
        [pointGraphics addObject:[self getGraphic4FixedPoint:geoPoint]];
    }
    
    [_mapView.graphicsOverlays[0].graphics addObjectsFromArray:pointGraphics];
}

- (void)stopBuildingGeometry {
    AGSGeometry *geometry;
    if (enableModification) {
        [_midPoints removeAllObjects];
    }
    [_mapView.graphicsOverlays[0].graphics removeAllObjects];
    
    if (_geoType == AGSGeometryTypePolyline) {
        geometry = [self drawPolylineWithUnfixedPoint:nil];
    }
    else
    {
        geometry = [self drawPolygonWithUnfixedPoint:nil];
    }
    if (self.delegate != nil) {
        [self.delegate FZISGeoBuilder:self didFinishBuildingGeometry:geometry withPoints:_geoPoints];
    }
}

- (void)cleanup {
    if ([_geoPoints count] > 0) {
        [_geoPoints removeAllObjects];
    }
    if ([_midPoints count] > 0) {
        [_midPoints removeAllObjects];
    }
    [_mapView.graphicsOverlays[0].graphics removeAllObjects];
    
    
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

- (AGSGraphic *)getGraphic4UnfixedPoint:(AGSGeometry *)geometry {
    AGSSimpleMarkerSymbol* markerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleCircle color:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5] size:10.0];
    AGSSimpleLineSymbol *outline = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor colorWithWhite:0.3 alpha:0.5] width:1.0];
    markerSymbol.outline = outline;
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:geometry symbol:markerSymbol attributes:nil];
    return graphic;
}

- (AGSGraphic *)getGraphic4FixedPoint:(AGSGeometry *)geometry {
    AGSSimpleMarkerSymbol* markerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleSquare color:[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5] size:10.0];
    AGSSimpleLineSymbol *outline = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor colorWithWhite:0.3 alpha:0.5] width:1.0];
    markerSymbol.outline = outline;
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:geometry symbol:markerSymbol attributes:nil];
    return graphic;
}

- (AGSGraphic *)getGraphic4MidPoint:(AGSGeometry *)geometry {
    AGSSimpleMarkerSymbol* markerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleCircle color:[UIColor colorWithWhite:1.0 alpha:0.5] size:10.0];
    AGSSimpleLineSymbol *outline = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor colorWithWhite:0.3 alpha:0.5] width:1.0];
    markerSymbol.outline = outline;
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:geometry symbol:markerSymbol attributes:nil];
    return graphic;
}

- (AGSGraphic *)getGraphic4Polyline:(AGSGeometry *)geometry {
    AGSSimpleLineSymbol * lineSymbol = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.8] width:2.0];
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:geometry symbol:lineSymbol attributes:nil];
    return graphic;
}

- (AGSGraphic *)getGraphic4Polygon:(AGSGeometry *)geometry {
    AGSSimpleLineSymbol * lineSymbol = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor cyanColor] width:2.0];
    AGSSimpleFillSymbol * fillSymbol = [AGSSimpleFillSymbol simpleFillSymbolWithStyle:AGSSimpleFillSymbolStyleSolid color:[UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.5] outline:lineSymbol];
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:geometry symbol:fillSymbol attributes:nil];
    return graphic;
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
