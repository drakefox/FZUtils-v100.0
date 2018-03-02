//
//  FZISGeoBuilder.h
//  FZISUtils
//
//  Created by fzis299 on 16/1/14.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
//#import "FZISMapView.h"

@class FZISMapView;

@protocol FZISGeoBuilderDelegate;

@interface FZISGeoBuilder : NSObject
<AGSCalloutDelegate>
{
//    FZISMeasurementType _measurementType;
    AGSGeometryType _geoType;
    NSMutableArray *_geoPoints;
    NSMutableArray *_midPoints;
    BOOL _isEditing;
    NSInteger _insertIndex;
    __weak FZISMapView *_mapView;
}

//@property (nonatomic, assign) AGSGeometryType geoType;
@property (nonatomic, assign) BOOL enableModification;
@property (nonatomic, weak) id<FZISGeoBuilderDelegate> delegate;

- (FZISGeoBuilder *)initWithMapView:(FZISMapView *)mapView;
- (void)startBuildingPolyline;
- (void)startBuildingPolygon;
- (void)updateWithScreenPoint:(CGPoint) screenPoint mapPoint:(AGSPoint *)mapPoint;
- (void)stopBuildingGeometry;
- (void)cleanup;
//- (void)updatePosition;
@end

@protocol FZISGeoBuilderDelegate <NSObject>

@required

- (void)FZISGeoBuilder:(FZISGeoBuilder *)builder didUpdatedGeometry:(AGSGeometry *)geometry withPoints:(NSArray *)points;
- (void)FZISGeoBuilder:(FZISGeoBuilder *)builder didFinishBuildingGeometry:(AGSGeometry *)geometry withPoints:(NSArray *)points;

@end
