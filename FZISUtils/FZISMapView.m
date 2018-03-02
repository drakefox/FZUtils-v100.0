//
//  FZISMapView.m
//  FZISUtils
//
//  Created by fzis299 on 2017/7/13.
//  Copyright © 2017年 FZIS. All rights reserved.
//

#import "FZISMapView.h"
#import "CrossMarkView.h"



@implementation FZISMapView

@synthesize filePath, mapStatus, isPrecisePickingPoint;
@synthesize nameFieldSettings, keyFieldsSettings, detailFieldsSettings, fieldConvSettings, maxScaleSettings, minScaleSettings, canQuerySettings, isVisibleSettings, invisibleLayers, layerTree;
@synthesize basemapLayerInfo;
@synthesize geoBuilder;

- (void)initMapView {
    self.filePath = [NSString stringWithFormat:@"%@/Documents",NSHomeDirectory()];
    
    AGSBackgroundGrid *grid = [AGSBackgroundGrid backgroundGridWithColor:[UIColor whiteColor] gridLineColor:[UIColor clearColor] gridLineWidth:0.0 gridSize:2.0];
    self.backgroundGrid = grid;
    self.interactionOptions.rotateEnabled = NO;
    self.interactionOptions.allowMagnifierToPan = NO;
    self.interactionOptions.magnifierEnabled = NO;
    [self parseBasemapLayerSettings];
    [self parseLayerSettings];
    
    AGSGraphicsOverlay *graphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
    
    [self.graphicsOverlays addObject:graphicsOverlay];
    
    self.callout.delegate = self;
//    self.touchDelegate = self;
    
    _measurementTool = [[FZISMeasurementTool alloc] initWithMapView:self];
    _gpsTool = [[FZISGPSTool alloc] initWithMapView:self];    
    geoBuilder = [[FZISGeoBuilder alloc] initWithMapView:self];
    
    [self customizeGestureRecognizers];
    [self addObservers];   
    
    
    NSString *gdbPath = [NSString stringWithFormat:@"%@/GDBLayer/GDBLayers.geodatabase", self.filePath, nil];
    _geodatabase = [AGSGeodatabase geodatabaseWithFileURL:[NSURL fileURLWithPath:gdbPath]];
    __weak typeof(self) weakSelf = self;
    [_geodatabase loadWithCompletion:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error != nil) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: error.localizedDescription};
            NSError *myError = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:loadGeodatabaseError userInfo:userInfo];
            if (strongSelf.operationHandler != nil && [strongSelf.operationHandler respondsToSelector:@selector(operationFailedWithError:)]) {
                [strongSelf.operationHandler operationFailedWithError:myError];
            }
        }
        else {
            if (strongSelf.operationHandler != nil && [strongSelf.operationHandler respondsToSelector:@selector(operationCompleted)]) {
                [strongSelf.operationHandler operationCompleted];
            }
        }        
    }];
}

- (void)customizeGestureRecognizers {
    
    UITapGestureRecognizer *tapWithSingleTouchGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapWithSingleTouchReceived:)];
    
    UITapGestureRecognizer *tapWithDoubleTouchesGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapWithDoubleTouchesReceived:)];
    
    for (UIGestureRecognizer *recgnizer in [self gestureRecognizers]) {
        if ([recgnizer isKindOfClass:[UITapGestureRecognizer class]]) {
            UITapGestureRecognizer *tapgesture = (UITapGestureRecognizer *)recgnizer;
            if (tapgesture.numberOfTouchesRequired == 2) {
                tapgesture.enabled = NO;
            }
        }

        if ([recgnizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [tapWithSingleTouchGestureRecognizer requireGestureRecognizerToFail:recgnizer];
        }
        
        if ([recgnizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
            [tapWithDoubleTouchesGestureRecognizer requireGestureRecognizerToFail:recgnizer];
        }
    }
    
    tapWithDoubleTouchesGestureRecognizer.numberOfTapsRequired = 1;
    tapWithDoubleTouchesGestureRecognizer.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:tapWithDoubleTouchesGestureRecognizer];
    
    
    tapWithSingleTouchGestureRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapWithSingleTouchGestureRecognizer];
}

- (void)addObservers {
    [self addObserver:self forKeyPath:@"mapStatus" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"isPrecisePickingPoint" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)tapWithDoubleTouchesReceived:(UITapGestureRecognizer *)gestureRecognizer
{
    if (mapStatus == statusMeasureDistance || mapStatus == statusMeasureArea) {
        [_measurementTool stopMeasurement];
        mapStatus = mapStatus + 1;
    }
    
}

- (void)tapWithSingleTouchReceived:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint screenPoint = isPrecisePickingPoint? [self center] : [gestureRecognizer locationInView:self];
    AGSPoint *measurePoint = [self screenToLocation:screenPoint];
    
    
    switch (mapStatus) {
        case statusMeasureDistance: case statusMeasureArea:
            geoBuilder.delegate = _measurementTool;
            [_measurementTool updateWithScreenPoint:screenPoint mapPoint:measurePoint];
            break;
        case statusMeasureDistanceEnd: case statusMeasureAreaEnd:
            mapStatus = mapStatus - 1;
            [_measurementTool cleanup];
            [_measurementTool updateWithScreenPoint:screenPoint mapPoint:measurePoint];
            break;
        default:
            break;
    }
}

- (void)loadBasemap: (NSString *)layerName {
//    NSLog(@"loading basemap");
    
    NSDictionary *dicTPK = [basemapLayerInfo objectForKey:@"TPK"];
    NSDictionary *dicVTPK = [basemapLayerInfo objectForKey:@"VTPK"];
    
    AGSBasemap *basemap;
    
    if ([[dicTPK allKeys] containsObject:layerName]) {
        NSString *tpkPath = [NSString stringWithFormat:@"%@/TPK/%@", self.filePath, [dicTPK objectForKey:layerName], nil];
        AGSArcGISTiledLayer *tiledLayer = [AGSArcGISTiledLayer ArcGISTiledLayerWithTileCache:[AGSTileCache tileCacheWithFileURL:[NSURL fileURLWithPath:tpkPath]]];
        basemap = [AGSBasemap basemapWithBaseLayer:tiledLayer];
        
    }
    else if ([[dicVTPK allKeys] containsObject:layerName]) {
        NSString *vtpkPath = [NSString stringWithFormat:@"%@/VTPK/%@", self.filePath, [dicVTPK objectForKey:layerName], nil];
        AGSArcGISVectorTiledLayer *vtiledLayer = [AGSArcGISVectorTiledLayer ArcGISVectorTiledLayerWithURL:[NSURL fileURLWithPath:vtpkPath]];
        basemap = [AGSBasemap basemapWithBaseLayer:vtiledLayer];
    }
    else {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"未找到可用的底图文件！"};
        NSError *myError = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:loadBasemapError userInfo:userInfo];
        if (self.operationHandler != nil && [self.operationHandler respondsToSelector:@selector(operationFailedWithError:)]) {
            [self.operationHandler operationFailedWithError:myError];
        }
        return;
    }
    
    basemap.name = layerName;
    
    if (self.map == nil) {
        self.map = [AGSMap mapWithBasemap:basemap];
//        NSLog(@"nil map");
    }
    else {
        self.map.basemap = basemap;
//        NSLog(@"basemap change");
    }
}

- (void)parseBasemapLayerSettings
{
    NSString *configPath = [NSString stringWithFormat:@"%@/BasemapConfig.plist", self.filePath, nil];
    basemapLayerInfo = [[NSDictionary alloc] initWithContentsOfFile:configPath];
}

- (void)parseLayerSettings
{
//    NSString *basePath = [NSString stringWithFormat:@"%@/Documents",NSHomeDirectory()];
    NSString *configPath = [NSString stringWithFormat:@"%@/LayerConfig.plist", self.filePath, nil];
    
    layerTree = [[NSDictionary alloc] initWithContentsOfFile:configPath];
    
    nameFieldSettings = [[NSMutableDictionary alloc] init];
    fieldConvSettings = [[NSMutableDictionary alloc] init];
    detailFieldsSettings = [[NSMutableDictionary alloc] init];
    keyFieldsSettings = [[NSMutableDictionary alloc] init];
    maxScaleSettings = [[NSMutableDictionary alloc] init];
    minScaleSettings = [[NSMutableDictionary alloc] init];
    canQuerySettings = [[NSMutableDictionary alloc] init];
    isVisibleSettings = [[NSMutableDictionary alloc] init];
    invisibleLayers = [[NSMutableDictionary alloc] init];
    
    if ([layerTree objectForKey:@"nameField"] != nil && [[layerTree objectForKey:@"nameField"] count] > 0) {
        [nameFieldSettings setValuesForKeysWithDictionary:[layerTree objectForKey:@"nameField"]];
    }
    
    if ([layerTree objectForKey:@"keyFields"] != nil && [[layerTree objectForKey:@"keyFields"] count] > 0) {
        [keyFieldsSettings setValuesForKeysWithDictionary:[layerTree objectForKey:@"keyFields"]];
    }
    
    if ([layerTree objectForKey:@"fieldConv"] != nil && [[layerTree objectForKey:@"fieldConv"] count] > 0) {
        [fieldConvSettings setValuesForKeysWithDictionary:[layerTree objectForKey:@"fieldConv"]];
    }
    
    if ([layerTree objectForKey:@"detailFields"] != nil && [[layerTree objectForKey:@"detailFields"] count] > 0) {
        [detailFieldsSettings setValuesForKeysWithDictionary:[layerTree objectForKey:@"detailFields"]];
    }
    
    if ([layerTree objectForKey:@"maxScale"] != nil) {
        [maxScaleSettings setObject:[layerTree objectForKey:@"maxScale"] forKey:[layerTree objectForKey:@"title"]];
    }
    
    if ([layerTree objectForKey:@"minScale"] != nil) {
        [minScaleSettings setObject:[layerTree objectForKey:@"minScale"] forKey:[layerTree objectForKey:@"title"]];
    }
    
    if ([layerTree objectForKey:@"canQuery"] != nil) {
        [canQuerySettings setObject:[layerTree objectForKey:@"canQuery"] forKey:[layerTree objectForKey:@"title"]];
    }
    
    if ([layerTree objectForKey:@"isVisible"] != nil) {
        [isVisibleSettings setObject:[layerTree objectForKey:@"isVisible"] forKey:[layerTree objectForKey:@"title"]];
    }
    
    for (NSDictionary *layerInfo in [layerTree objectForKey:@"children"]) {
        [self getFieldSettings4Layer:layerInfo];
    }
}

- (void)getFieldSettings4Layer:(NSDictionary *)layerInfo
{
    if ([layerInfo objectForKey:@"nameField"] != nil && [[layerInfo objectForKey:@"nameField"] count] > 0) {
        [nameFieldSettings setValuesForKeysWithDictionary:[layerInfo objectForKey:@"nameField"]];
    }
    
    if ([layerInfo objectForKey:@"keyFields"] != nil && [[layerInfo objectForKey:@"keyFields"] count] > 0) {
        [keyFieldsSettings setValuesForKeysWithDictionary:[layerInfo objectForKey:@"keyFields"]];
    }
    
    if ([layerInfo objectForKey:@"fieldConv"] != nil && [[layerInfo objectForKey:@"fieldConv"] count] > 0) {
        [fieldConvSettings setValuesForKeysWithDictionary:[layerInfo objectForKey:@"fieldConv"]];
    }
    
    if ([layerInfo objectForKey:@"detailFields"] != nil && [[layerInfo objectForKey:@"detailFields"] count] > 0) {
        [detailFieldsSettings setValuesForKeysWithDictionary:[layerInfo objectForKey:@"detailFields"]];
    }
    
    if ([layerInfo objectForKey:@"maxScale"] != nil) {
        [maxScaleSettings setObject:[layerInfo objectForKey:@"maxScale"] forKey:[layerInfo objectForKey:@"title"]];
    }
    
    if ([layerInfo objectForKey:@"minScale"] != nil) {
        [minScaleSettings setObject:[layerInfo objectForKey:@"minScale"] forKey:[layerInfo objectForKey:@"title"]];
    }
    
    if ([layerInfo objectForKey:@"canQuery"] != nil) {
        [canQuerySettings setObject:[layerInfo objectForKey:@"canQuery"] forKey:[layerInfo objectForKey:@"title"]];
    }
    
    if ([layerInfo objectForKey:@"isVisible"] != nil) {
        [isVisibleSettings setObject:[layerInfo objectForKey:@"isVisible"] forKey:[layerInfo objectForKey:@"title"]];
        if ([[layerInfo objectForKey:@"nodeType"] integerValue] == 0 && [[layerInfo objectForKey:@"isVisible"] integerValue] == 0) {
            [invisibleLayers setObject:[layerInfo objectForKey:@"layerType"] forKey:[layerInfo objectForKey:@"title"]];
        }
    }
    
    if ([[layerTree objectForKey:@"children"] count] > 0) {
        for (NSDictionary *subLayerInfo in [layerInfo objectForKey:@"children"]) {
            [self getFieldSettings4Layer:subLayerInfo];
        }
    }
}

- (void)loadGDBLayerWithName:(NSString *)layerName {
    AGSGeodatabaseFeatureTable *featureTable = [_geodatabase geodatabaseFeatureTableWithName:layerName];
    AGSFeatureLayer *featureLayer = [AGSFeatureLayer featureLayerWithFeatureTable:featureTable];
    featureLayer.name = layerName;
    [self.map.operationalLayers addObject:featureLayer];
}

- (void)loadServiceLayerFromUrl:(NSString *)url WithName:(NSString *)layerName {
    AGSServiceFeatureTable *featureTable = [AGSServiceFeatureTable serviceFeatureTableWithURL:[NSURL URLWithString:url]];
    AGSFeatureLayer *featureLayer = [AGSFeatureLayer featureLayerWithFeatureTable:featureTable];
    featureLayer.name = layerName;
    [featureLayer loadWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
    [self.map.operationalLayers addObject:featureLayer];
}

- (void)removeLayerWithName:(NSString *)layerName {
    AGSLayer *layerToRemove = [self getLayerByName:layerName];
    if (layerToRemove != nil) {
        [self.map.operationalLayers removeObject:layerToRemove];
    }
}

- (AGSLayer *)getLayerByName:(NSString *)layerName {
    for (AGSLayer *layer in self.map.operationalLayers) {
        if ([layer.name isEqualToString:layerName]) {
            return layer;
        }
    }
    return nil;
}

- (void)drawCrossMark
{
    CrossMarkView *crossMark = [[CrossMarkView alloc] initWithFrame:self.frame];
    [self addSubview:crossMark];
}

- (void)clearCrossMark
{
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[CrossMarkView class]]) {
            [view removeFromSuperview];
        }
    }
}

- (void)startLocationDisplay
{
    [_gpsTool startLocationDisplay];
}

- (void)stopLocationDisplay
{
    [_gpsTool stopLocationDisplay];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"mapStatus"]) {
        NSInteger statusOld = [[change objectForKey:@"old"] integerValue];
        
        switch (mapStatus) {
            case statusMeasureDistance:
                [_measurementTool startDistanceMeasurement];
                break;
            case statusMeasureArea:
                [_measurementTool startAreaMeasurement];
                break;
            default:
                //NSLog(@"%ld, %ld",(long)statusNew, (long)statusOld);
                if (statusOld == statusMeasureDistance ||
                    statusOld == statusMeasureDistanceEnd ||
                    statusOld == statusMeasureArea ||
                    statusOld == statusMeasureAreaEnd) {
                    [_measurementTool cleanup];
                }                
                break;
        }
    }
    else if ([keyPath isEqualToString:@"isPrecisePickingPoint"]) {
        if (isPrecisePickingPoint) {
            [self drawCrossMark];
        }
        else
        {
            [self clearCrossMark];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end
