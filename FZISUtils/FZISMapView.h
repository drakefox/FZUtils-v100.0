//
//  FZISMapView.h
//  FZISUtils
//
//  Created by fzis299 on 2017/7/13.
//  Copyright © 2017年 FZIS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>
#import "FZISMeasurementTool.h"
#import "FZISGPSTool.h"
#import "GlobeDefinitions.h"

@protocol FZISMapViewOperationHandleDelegate;

@interface FZISMapView : AGSMapView
<AGSCalloutDelegate, AGSGeoViewTouchDelegate>
{
    FZISMeasurementTool *_measurementTool;
    FZISGPSTool *_gpsTool;
    AGSGeodatabase *_geodatabase;
}

@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, assign) FZISMapViewStatus mapStatus;
@property (nonatomic, assign) BOOL isPrecisePickingPoint;

@property (nonatomic, retain) FZISGeoBuilder *geoBuilder;

//@property (nonatomic, retain) FZISMeasurementTool *measurementTool;

@property (nonatomic, retain) NSDictionary *layerTree;
@property (nonatomic, retain) NSMutableDictionary *nameFieldSettings;
@property (nonatomic, retain) NSMutableDictionary *keyFieldsSettings;
@property (nonatomic, retain) NSMutableDictionary *detailFieldsSettings;
@property (nonatomic, retain) NSMutableDictionary *fieldConvSettings;
@property (nonatomic, retain) NSMutableDictionary *maxScaleSettings;
@property (nonatomic, retain) NSMutableDictionary *minScaleSettings;
@property (nonatomic, retain) NSMutableDictionary *canQuerySettings;
@property (nonatomic, retain) NSMutableDictionary *isVisibleSettings;
@property (nonatomic, retain) NSMutableDictionary *invisibleLayers;

@property (nonatomic, retain) NSDictionary *basemapLayerInfo;

@property (nonatomic, weak) id<FZISMapViewOperationHandleDelegate> operationHandler;

- (void)initMapView;
- (void)loadBasemap: (NSString *)layerName;
- (void)loadGDBLayerWithName:(NSString *)layerName;
- (void)loadServiceLayerFromUrl:(NSString *)url WithName:(NSString *)layerName;
- (void)removeLayerWithName:(NSString *)layerName;

- (AGSLayer *)getLayerByName:(NSString *)layerName;

- (void)startLocationDisplay;
- (void)stopLocationDisplay;

@end

@protocol FZISMapViewOperationHandleDelegate <NSObject>

@optional
- (void)operationFailedWithError:(NSError *)error;
- (void)operationCompleted;

@end
