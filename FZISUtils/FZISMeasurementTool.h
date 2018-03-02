//
//  FZISMeasurementTool.h
//  FZISUtils
//
//  Created by fzis299 on 16/1/14.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "FZISGeoBuilder.h"

@class FZISMapView;

#define kLabelOffset CGPointMake(0, -20);

typedef enum {
    measureDistance = 0,
    measureArea
}FZISMeasurementType;

@interface FZISMeasurementTool : NSObject
<AGSCalloutDelegate, FZISGeoBuilderDelegate>
{
    FZISMeasurementType _measurementType;
//    FZISGeoBuilder *_geoBuilder;
    NSMutableArray *_measurementPoints;
//    AGSGraphic *_lastLabelGraphic;
//    NSMutableArray *_tmpGraphics;
//    UIButton *_btnCleanup;
    __weak FZISMapView *_mapView;
}

- (FZISMeasurementTool *)initWithMapView:(FZISMapView *)mapView;
- (void)startDistanceMeasurement;
- (void)startAreaMeasurement;
- (void)updateWithScreenPoint:(CGPoint) screenPoint mapPoint:(AGSPoint *)mapPoint;
- (void)stopMeasurement;
- (void)cleanup;
//- (void)updatePosition;
@end
