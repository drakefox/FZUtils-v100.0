//
//  FZISQueryTool.m
//  FZISUtils
//
//  Created by fzis299 on 16/1/19.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import "FZISQueryTool.h"
#import "FZISMapView.h"


@implementation FZISQueryTool

@synthesize queryGraphic;


- (FZISQueryTool *)initWithMapView:(FZISMapView *)mapView
{
    self = [super init];
    if (self) {
        _mapView = mapView;
        
        _results = [[NSMutableDictionary alloc] init];
//        _networkTool = [[FZISNetworkTool alloc] init];
//        _networkTool.delegate = self;
        
//        _queryTasks = [[NSMutableDictionary alloc] init];
//        _layerNameDic = [[NSMutableDictionary alloc] init];
        
        _statisticLayer = nil;
    }
    
    return self;
}

//- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features
//{
//    NSMutableDictionary *results = [[NSMutableDictionary alloc] initWithDictionary:features];
//    for (NSString *layerName in [results allKeys]) {
//        if (![_mapView.SHPLayers containsObject:layerName] && ![_mapView.TILEDLayers containsObject:layerName] && ![_mapView.GDBLayers containsObject:layerName]) {
//            [results removeObjectForKey:layerName];
//        }
//    }
//    
//    [_mapView.sketchLayer removeAllGraphics];
//    queryGraphic = nil;//[[AGSGraphic alloc] init];
//    
//    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISQueryTool:didExecuteWithQueryResult:)]) {
//        [self.delegate FZISQueryTool:self didExecuteWithQueryResult:results];
//    }    
//}

- (void)startSpatialQuery
{
    if (!_lineView) {
        _lineView = [[FZISLineView alloc] initWithFrame:_mapView.bounds];
    }
    _lineView.penColor = [UIColor redColor];
    _lineView.penWidth = 1.0;
    _lineView.penShape = shapeFreeLine;
    _lineView.lineViewDelegate = self;
    [_mapView addSubview:_lineView];
}

- (void)startStatisticOnLayer:(AGSLayer *)layer
{
    _statisticLayer = layer;
    
    if (!_lineView) {
        _lineView = [[FZISLineView alloc] initWithFrame:_mapView.bounds];
    }
    _lineView.penColor = [UIColor redColor];
    _lineView.penWidth = 1.0;
    _lineView.penShape = shapeFreeLine;
    _lineView.lineViewDelegate = self;
    [_mapView addSubview:_lineView];
}


- (void)startSearchWithKeyword:(NSString *)keyword{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISQueryToolWillExecute)]) {
        [self.delegate FZISQueryToolWillExecute];
    }
    
    [self performSelectorInBackground:@selector(queryFeaturesWithKeyword:) withObject:keyword];
    
//    [self performSelectorInBackground:@selector(queryResultMonitor) withObject:nil];
    
//    if ([_mapView.TILEDLayers count] > 0) {
//        [self performSelector:@selector(queryFeaturesOnTILEDLayersWithKeyword:) withObject:keyword afterDelay:0.5];
//    }
//    
//    if ([_mapView.GDBLayers count] > 0) {
//        [self performSelectorInBackground:@selector(queryFeaturesOnGDBLayersWithKeyword:) withObject:keyword];
//    }
//
//    if ([_mapView.SHPLayers count] > 0) {
//        [self performSelector:@selector(queryFeaturesOnSHPLayersWithKeyword:) withObject:keyword afterDelay:0.5];
//    }
}

- (void)startSearchWithKeyword:(NSString *)keyword onLayer:(NSString *)layerName{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISQueryToolWillExecute)]) {
        [self.delegate FZISQueryToolWillExecute];
    }
    
    AGSFeatureLayer *layer = (AGSFeatureLayer *)[_mapView getLayerByName:layerName];
    NSString *nameField = [_mapView.nameFieldSettings objectForKey:layerName];
    AGSQueryParameters *query = [[AGSQueryParameters alloc] init];
    query.whereClause = [NSString stringWithFormat:@"%@ like '%%%@%%'", nameField, keyword];
    //        NSLog(@"%@", query.whereClause);
    
    [layer.featureTable queryFeaturesWithParameters:query completion:^(AGSFeatureQueryResult * _Nullable result, NSError * _Nullable error) {
        if (error == nil) {
            [_results setObject:[result.featureEnumerator allObjects] forKey:layerName];
        }
        else
        {
            [_results setObject:[NSArray array] forKey:layerName];
        }
        
        [self notifyQueryDone];
    }];
}


- (void)startSearchWithKeyword:(NSString *)keyword onLayers:(NSArray *)layers{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISQueryToolWillExecute)]) {
        [self.delegate FZISQueryToolWillExecute];
    }
    
    NSMutableArray *validLayers = [[NSMutableArray alloc] init];
    
    for (NSString *layerName in layers) {
        AGSFeatureLayer *layer = (AGSFeatureLayer *)[_mapView getLayerByName:layerName];
        if (layer != nil) {
            [validLayers addObject:layerName];
        }
    }
    
    for (NSString *layerName in validLayers) {
        AGSFeatureLayer *layer = (AGSFeatureLayer *)[_mapView getLayerByName:layerName];
        NSString *nameField = [_mapView.nameFieldSettings objectForKey:layerName];
        AGSQueryParameters *query = [[AGSQueryParameters alloc] init];
        query.whereClause = [NSString stringWithFormat:@"%@ like '%%%@%%'", nameField, keyword];
        //        NSLog(@"%@", query.whereClause);
        
        [layer.featureTable queryFeaturesWithParameters:query completion:^(AGSFeatureQueryResult * _Nullable result, NSError * _Nullable error) {
            if (error == nil) {
                [_results setObject:[result.featureEnumerator allObjects] forKey:layerName];
            }
            else
            {
                [_results setObject:[NSArray array] forKey:layerName];
            }
            
            [self queryResultCheckForLayers:validLayers];
        }];
    }
    
    
}

- (void)lineViewTouchesBegan:(FZISLineView *)lineView
{
    [_mapView.graphicsOverlays[0].graphics removeAllObjects];
}

- (void)lineViewTouchesEnded: (FZISLineView *)lineView
{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISQueryToolWillExecute)]) {
        [self.delegate FZISQueryToolWillExecute];
    }
    
//    AGSMutablePolygon *polygon = [[AGSMutablePolygon alloc] init];//草图图形
//    [polygon addRingToPolygon];
    
    AGSPolygonBuilder *polygon = [AGSPolygonBuilder polygonBuilderWithSpatialReference:_mapView.spatialReference];
    
    NSMutableArray *points = lineView.points;
    for (int i = 0; i < [points count]; i++)
    {
        NSValue *pointItem = [points objectAtIndex:i];
        CGPoint screenPoint;
        [pointItem getValue:&screenPoint];
        
        AGSPoint *mapPoint = [_mapView screenToLocation:screenPoint];//屏幕坐标转地图坐标
        [polygon addPoint:mapPoint];
    }
    
    AGSSimpleLineSymbol *lineSymbol = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor purpleColor] width:1.0];
    AGSSimpleFillSymbol *fillSymbol = [AGSSimpleFillSymbol simpleFillSymbolWithStyle:AGSSimpleFillSymbolStyleSolid color:[UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.3] outline:lineSymbol];
    
    AGSGraphic * drawGraphic= [AGSGraphic graphicWithGeometry:[polygon toGeometry] symbol:fillSymbol attributes:nil];//创建草图
    [_mapView.graphicsOverlays[0].graphics addObject:drawGraphic];
    
    queryGraphic = drawGraphic;
    
    [_lineView.points removeAllObjects];
    [_lineView removeFromSuperview];
    
    NSDictionary *queryParams = [[NSDictionary alloc] initWithObjectsAndKeys:[polygon toGeometry], @"geometry", nil];
    
    if (_statisticLayer != nil) {
        [self caculateFeaturesOnLayerWithParams:queryParams];
    }
    else
    {
        [self performSelectorInBackground:@selector(queryFeaturesWithParams:) withObject:queryParams];
//        [self performSelectorInBackground:@selector(queryResultMonitor) withObject:nil];
//        
//        if ([_mapView.TILEDLayers count] > 0) {
//            [self performSelector:@selector(queryFeaturesOnTILEDLayersWithParams:) withObject:queryParams afterDelay:0.5];
//        }
//        
//        if ([_mapView.GDBLayers count] > 0) {
//            [self performSelectorInBackground:@selector(queryFeaturesOnGDBLayersWithParams:) withObject:queryParams];
//        }
//        
//        if ([_mapView.SHPLayers count] > 0) {
//            [self performSelector:@selector(queryFeaturesOnSHPLayersWithParams:) withObject:queryParams afterDelay:0.5];
//        }
    }
}

- (void)queryFeaturesWithParams:(NSDictionary *)params;
{
    //native api version, may throw exception due to the data defections
    AGSGeometry *geometry = [params objectForKey:@"geometry"];
    
    for (AGSLayer *layer in _mapView.map.operationalLayers) {
        
        //check whether this layer is visible - EriChen@2017.2.15
        AGSFeatureLayer *fLayer = (AGSFeatureLayer *)layer;
        if (![layer isVisibleAtScale:_mapView.mapScale]) {
            [_results setObject:[NSArray array] forKey:layer.name];
            continue;
        }
        
        AGSQueryParameters *query = [[AGSQueryParameters alloc] init];
        if (geometry != nil) {
            query.geometry = geometry;
            query.spatialRelationship = AGSSpatialRelationshipIntersects;
        }
        
        [fLayer.featureTable queryFeaturesWithParameters:query completion:^(AGSFeatureQueryResult * _Nullable result, NSError * _Nullable error) {
            if (error == nil) {
                [_results setObject:[result.featureEnumerator allObjects] forKey:layer.name];
            }
            else
            {
                [_results setObject:[NSArray array] forKey:layer.name];
            }
            [self queryResultMonitor];
        }];
    }
    
    //==================================================================================================
    
    //walkarround version, perform the spatial query ourselves
//    AGSGeometry *geometry = [params objectForKey:@"geometry"];
//    
//    for (NSString *layerName in _mapView.GDBLayers) {
//        AGSFeatureTableLayer *layer = (AGSFeatureTableLayer *)[_mapView mapLayerForName:layerName];
//        AGSQuery *query = [[AGSQuery alloc] init];
//        [layer.table queryResultsWithParameters:query completion:^(NSArray *results, NSError *error) {
//            if (error == nil) {
//                NSMutableArray *arrRes = [[NSMutableArray alloc] init];
//                AGSGeometryEngine *engine = [AGSGeometryEngine defaultGeometryEngine];
//                for (AGSGDBFeature *feature in results) {
//                    if ([engine geometry:geometry intersectsGeometry:feature.geometry]) {
//                        [arrRes addObject:feature];
//                    }
//                }
//                
//                [_results setObject:arrRes forKey:layerName];
//            }
//            else
//            {
//                [_results setObject:[NSArray array] forKey:layerName];
//            }
//        }];
//    }

}


- (void)queryFeaturesWithKeyword:(NSString *)keyword
{
    for (AGSLayer *layer in _mapView.map.operationalLayers) {
//        NSLog(@"%@/%@", layerName, keyword);
        AGSFeatureLayer *fLayer = (AGSFeatureLayer *)layer;
        NSString *nameField = [_mapView.nameFieldSettings objectForKey:layer.name];
        AGSQueryParameters *query = [[AGSQueryParameters alloc] init];
        query.whereClause = [NSString stringWithFormat:@"%@ like '%%%@%%'", nameField, keyword];
//        NSLog(@"%@", query.whereClause);
        
        [fLayer.featureTable queryFeaturesWithParameters:query completion:^(AGSFeatureQueryResult * _Nullable result, NSError * _Nullable error) {
            if (error == nil) {
                [_results setObject:[result.featureEnumerator allObjects] forKey:layer.name];
            }
            else
            {
                [_results setObject:[NSArray array] forKey:layer.name];
            }
            [self queryResultMonitor];
        }];
    }
}

- (void)caculateFeaturesOnLayerWithParams:(NSDictionary *)params
{
    AGSFeatureLayer *fLayer = (AGSFeatureLayer *)_statisticLayer;
    AGSGeometry *geometry = [params objectForKey:@"geometry"];
    AGSQueryParameters *query = [[AGSQueryParameters alloc] init];
    
    query.geometry = geometry;
    query.spatialRelationship = AGSSpatialRelationshipIntersects;
//    AGSOutStatistic *statistic = [[AGSOutStatistic alloc] init];
//    statistic.statisticType = AGSQueryStatisticsTypeSum;
//    statistic.onStatisticField = @"YDMJ";
//    statistic.outStatisticFieldName = @"YDMJ";
//    query.outStatistics = @[statistic];
//    query.groupByFieldsForStatistics = @[@"CGLBDM"];
    query.returnGeometry = NO;
    
    NSMutableDictionary *statisticRes = [[NSMutableDictionary alloc] init];
    
    [fLayer.featureTable queryFeaturesWithParameters:query completion:^(AGSFeatureQueryResult * _Nullable result, NSError * _Nullable error) {
        if (error == nil) {
//            for (AGSFeature *feature in [result.featureEnumerator allObjects]) {
//                [statisticRes setObject:[result objectForKey:@"YDMJ"] forKey:[result objectForKey:@"CGLBDM"]];
//            }
            for (AGSFeature *feature in [result.featureEnumerator allObjects]) {
                NSString *code = [[[feature attributes] objectForKey:@"CGLBDM"] substringToIndex:1];
                double area = [[[feature attributes] objectForKey:@"YDMJ"] doubleValue];
                if ([statisticRes.allKeys containsObject:code]) {
                    double currValue = [[statisticRes objectForKey:code] doubleValue];
                    currValue = currValue + area;
                    [statisticRes setObject:[NSString stringWithFormat:@"%.2f", currValue, nil] forKey:code];
                }
            }
        }
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISQueryTool:didExecuteWithStatisticResult:)]) {
            [self.delegate FZISQueryTool:self didExecuteWithStatisticResult:statisticRes];
        }
    }];
    
//    [fLayer.table queryResultsWithParameters:query completion:^(NSArray *results, NSError *error) {
//        if (error == nil) {
//            for (NSDictionary *result in results) {
//                [statisticRes setObject:[result objectForKey:@"YDMJ"] forKey:[result objectForKey:@"CGLBDM"]];
//            }
//            for (AGSGDBFeature *feature in results) {
//                NSString *code = [[[feature allAttributes] objectForKey:@"CGLBDM"] substringToIndex:1];
//                double area = [[[feature allAttributes] objectForKey:@"YDMJ"] doubleValue];
//                if ([statisticRes.allKeys containsObject:code]) {
//                    double currValue = [[statisticRes objectForKey:code] doubleValue];
//                    currValue = currValue + area;
//                    [statisticRes setObject:[ns] forKey:code];
//                }
//            }
//        }
//        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISQueryTool:didExecuteWithStatisticResult:)]) {
//            [self.delegate FZISQueryTool:self didExecuteWithStatisticResult:statisticRes];
//        }
//    }];
}

//- (void)queryFeaturesOnTILEDLayersWithParams:(NSDictionary *)params
//{
//    AGSGeometry *geometry = [params objectForKey:@"geometry"];
//    NSString *urlStr = [NSString stringWithFormat:@"%@?f=json&pretty=true", [_mapView.mapServerInfo objectForKey:@"BaseUrl"], nil];
//    _networkTool.url = [NSURL URLWithString:urlStr];
//    NSDictionary *requestRes = [_networkTool sendRequestByGET];
//    if ([requestRes objectForKey:@"error"] != nil) {
//        for (NSString *layerName in _mapView.TILEDLayers) {
//            [_results setObject:[NSArray array] forKey:layerName];
//        }
//    }
//    else
//    {
//        NSDictionary *layerInfo = [NSJSONSerialization JSONObjectWithData:[requestRes objectForKey:@"data"] options:NSJSONReadingMutableLeaves error:nil];
//        NSArray *layerList = [NSArray arrayWithArray:[layerInfo objectForKey:@"layers"]];
//        _tiledLayerIds = [self getLayerIdsByLayerNames:_mapView.TILEDLayers inLayerList:layerList];
//        _tiledLayerNames = [self getLayerNamesByLayerIds:_tiledLayerIds inLayerList:layerList];
//        [self onlineSpatialQuery:_tiledLayerIds queryGeometry:geometry];
//    }
//}

//- (void)queryFeaturesOnTILEDLayersWithKeyword:(NSString *)keyword
//{
////    AGSGeometry *geometry = [params objectForKey:@"geometry"];
//    NSString *urlStr = [NSString stringWithFormat:@"%@?f=json&pretty=true", [_mapView.mapServerInfo objectForKey:@"BaseUrl"], nil];
//    _networkTool.url = [NSURL URLWithString:urlStr];
//    NSDictionary *requestRes = [_networkTool sendRequestByGET];
//    if ([requestRes objectForKey:@"error"] != nil) {
//        for (NSString *layerName in _mapView.TILEDLayers) {
//            [_results setObject:[NSArray array] forKey:layerName];
//        }
//    }
//    else
//    {
//        NSDictionary *layerInfo = [NSJSONSerialization JSONObjectWithData:[requestRes objectForKey:@"data"] options:NSJSONReadingMutableLeaves error:nil];
//        NSArray *layerList = [NSArray arrayWithArray:[layerInfo objectForKey:@"layers"]];
//        _tiledLayerIds = [self getLayerIdsByLayerNames:_mapView.TILEDLayers inLayerList:layerList];
//        _tiledLayerNames = [self getLayerNamesByLayerIds:_tiledLayerIds inLayerList:layerList];
//        [self onlineKeywordSearch:_tiledLayerIds Keyword:keyword];
//    }
//}



//- (void)queryFeaturesOnSHPLayersWithParams:(NSDictionary *)params
//{
//    AGSGeometry *geometry = [params objectForKey:@"geometry"];
//    
//    for (NSString *layerName in _mapView.SHPLayers) {
//        
//        NSMutableArray *featuresOnLayer = [[NSMutableArray alloc] init];
//        
//        AGSLayer *layerView =[_mapView mapLayerForName:layerName];
//        AGSGraphicsLayer *layer = (AGSGraphicsLayer*)layerView;
//        NSMutableArray *graphicsData = [[NSMutableArray alloc] initWithArray:layer.graphics];
//        
//        for (int i = 0; i < [graphicsData count]; i++) {//查找符合条件的图形
//            AGSGraphic * graphic = [graphicsData objectAtIndex:i];
//            AGSGeometry *featureGeo = graphic.geometry;
//            
//            AGSGeometryType geometryType = AGSGeometryTypeForGeometry(featureGeo);
//            AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
//            
//            if (geometryType == AGSGeometryTypePoint) {//点
//                BOOL contains = [geometryEngine geometry:geometry containsGeometry:featureGeo];
//                if (contains) {
//                    [featuresOnLayer addObject:graphic];
//                    continue;
//                }
//            }
//            else if(geometryType == AGSGeometryTypePolyline) {//线
//                BOOL contains = [geometryEngine geometry:geometry containsGeometry:featureGeo];
//                if (contains) {
//                    [featuresOnLayer addObject:graphic];
//                    continue;
//                }
//                BOOL crosses = [geometryEngine geometry:geometry crossesGeometry:featureGeo];
//                if (crosses) {
//                    [featuresOnLayer addObject:graphic];
//                    continue;
//                }
//            }
//            else{//面
//                BOOL contains = [geometryEngine geometry:geometry containsGeometry:featureGeo];
//                if (contains) {
//                    [featuresOnLayer addObject:graphic];
//                    continue;
//                }
//                BOOL overlaps = [geometryEngine geometry:geometry overlapsGeometry:featureGeo];
//                if (overlaps) {
//                    [featuresOnLayer addObject:graphic];
//                    continue;
//                }
//                BOOL within = [geometryEngine geometry:geometry withinGeometry:featureGeo];
//                if (within) {
//                    [featuresOnLayer addObject:graphic];
//                    continue;
//                }
//                
//            }
//        }
//        
//        [_results setObject:featuresOnLayer forKey:layerName];
//    }
//}

//- (void)queryFeaturesOnSHPLayersWithKeyword:(NSString *)keyword
//{
//    for (NSString *layerName in _mapView.SHPLayers) {
//        
//        NSMutableArray *featuresOnLayer = [[NSMutableArray alloc] init];
//        
//        AGSLayer *layerView =[_mapView mapLayerForName:layerName];
//        AGSGraphicsLayer *layer = (AGSGraphicsLayer*)layerView;
//        NSMutableArray *graphicsData = [[NSMutableArray alloc] initWithArray:layer.graphics];
//        
//        NSString *nameField = [_mapView.nameFieldSettings objectForKey:layerName];
//        
//        for (int i = 0; i < [graphicsData count]; i++) {//查找符合条件的图形
//            AGSGraphic * graphic = [graphicsData objectAtIndex:i];
//            NSDictionary *attributes = [graphic allAttributes];
//            NSString *fieldValue = [attributes objectForKey:nameField];
//            if ([fieldValue rangeOfString:keyword].length > 0) {
//                [featuresOnLayer addObject:graphic];
//            }
//        }
//        
//        [_results setObject:featuresOnLayer forKey:layerName];
//    }
//}

//- (void)onlineSpatialQuery:(NSArray *)layerIds queryGeometry:(AGSGeometry *)queryGeo
//{
//    AGSGeometryType geometryType = AGSGeometryTypeForGeometry(queryGeo);
//    
//    NSString *baseUrl = [_mapView.mapServerInfo objectForKey:@"BaseUrl"];
//    
//    _identifyTask = [AGSIdentifyTask identifyTaskWithURL:[NSURL URLWithString:baseUrl]];
//    _identifyTask.delegate = self;
//    
//    _identifyParams = [[AGSIdentifyParameters alloc] init];
//    
//    _identifyParams.layerIds = layerIds;
//    _identifyParams.tolerance = (geometryType == AGSGeometryTypePoint) ? 10 : 0;
//    _identifyParams.geometry = queryGeo;
//    _identifyParams.size = _mapView.bounds.size;
//    _identifyParams.mapEnvelope = _mapView.visibleArea.envelope;
//    _identifyParams.returnGeometry = YES;
//    _identifyParams.layerOption = AGSIdentifyParametersLayerOptionAll;
//    _identifyParams.spatialReference = _mapView.spatialReference;
//    
//    //execute the task
//    [_identifyTask executeWithParameters:_identifyParams];
//    
//}

//- (void)onlineKeywordSearch:(NSArray *)layerIds Keyword:(NSString *)keyword
//{
//    NSString *baseUrl = [_mapView.mapServerInfo objectForKey:@"BaseUrl"];
//    
//    for (int i = 0; i < [layerIds count]; i++) {
//        NSInteger layerId = [[layerIds objectAtIndex:i] integerValue];
//        NSString *layerUrl = [NSString stringWithFormat:@"%@/%ld", baseUrl, (long)layerId];
//        AGSQueryTask *queryTask = [AGSQueryTask queryTaskWithURL:[NSURL URLWithString:layerUrl]];
//        queryTask.delegate = self;
//        
//        NSString *layerName = [_layerNameDic objectForKey:[layerIds objectAtIndex:i]];
//        
//        NSString *nameField = [_mapView.nameFieldSettings objectForKey:layerName];
//        
//        AGSQuery *query = [[AGSQuery alloc] init];
//        query.whereClause = [NSString stringWithFormat:@"%@ like %%%@%%", nameField, keyword];
//        
//        [_queryTasks setObject:queryTask forKey:layerName];
//        
//        [queryTask executeWithQuery:query];
//    }
//    
//}

//- (void)identifyTask:(AGSIdentifyTask *)identifyTask operation:(NSOperation *)op didExecuteWithIdentifyResults:(NSArray *)results
//{
//    NSArray *layerNames = [[NSArray alloc] initWithArray:_tiledLayerNames copyItems:YES];
//    
//    [_tiledLayerNames removeAllObjects];
//    [_tiledLayerIds removeAllObjects];
//    
//    NSMutableDictionary *resultProcessed = [[NSMutableDictionary alloc] init];
//    
//    for (NSString *layerName in layerNames) {
//        NSMutableArray *resPlaceHolder = [[NSMutableArray alloc] init];
//        [resultProcessed setObject:resPlaceHolder forKey:layerName];
//    }
//    [_tiledLayerNames removeAllObjects];
//    
//    for (AGSIdentifyResult *result in results)
//    {
//        NSString *layer = [result layerName];
//        
//        NSMutableArray *featuresOnLayer = [resultProcessed objectForKey:layer];
////        NSLog(@"%@", [[result.feature allAttributes] objectForKey:@"物探点号"], nil);
//        [featuresOnLayer addObject:result.feature];
//    }
//    [_results setValuesForKeysWithDictionary:resultProcessed];
//}
//
//- (void)identifyTask:(AGSIdentifyTask *)identifyTask operation:(NSOperation *)op didFailWithError:(NSError *)error
//{
//    NSArray *layerNames = [[NSArray alloc] initWithArray:_tiledLayerNames copyItems:YES];
//    
//    [_tiledLayerNames removeAllObjects];
//    [_tiledLayerIds removeAllObjects];
//    
//    for (NSString *layerName in layerNames) {
//        [_results setObject:[NSArray array] forKey:layerName];
//    }
//}
//
//- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didExecuteWithFeatureSetResult:(AGSFeatureSet *)featureSet
//{
//    NSString *layerName = @"";
//    for (NSString *tmpLayerName in _tiledLayerNames) {
//        AGSQueryTask *task = [_queryTasks objectForKey:tmpLayerName];
//        if ([task isEqual:queryTask]) {
//            layerName = tmpLayerName;
//            break;
//        }
//    }
//    [_results setObject:[featureSet features] forKey:layerName];
//}
//
//- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didFailWithError:(NSError *)error
//{
//    NSString *layerName = @"";
//    for (NSString *tmpLayerName in _tiledLayerNames) {
//        AGSQueryTask *task = [_queryTasks objectForKey:tmpLayerName];
//        if ([task isEqual:queryTask]) {
//            layerName = tmpLayerName;
//            break;
//        }
//    }
//    
//    [_results setObject:[NSArray array] forKey:layerName];
//}

//- (NSMutableArray *)getLayerIdsByLayerNames:(NSArray *)layerNames inLayerList:(NSArray *)layerList
//{
//    NSMutableArray *layerIds = [[NSMutableArray alloc] init];
//    for (NSDictionary *layerInfo in layerList) {
//        NSString *layerName = [layerInfo objectForKey:@"name"];
//        id layerId = [layerInfo objectForKey:@"id"];
//        if ([layerNames containsObject:layerName]) {
//            if ([layerInfo objectForKey:@"subLayerIds"] == nil) {
//                [layerIds addObject:layerId];
//            }
//            else
//            {
//                [layerIds addObjectsFromArray:[layerInfo objectForKey:@"subLayerIds"]];
//            }
//        }
//    }
//    return layerIds;
//}
//
//- (NSMutableArray *)getLayerNamesByLayerIds:(NSArray *)layerIds inLayerList:(NSArray *)layerList
//{
//    NSMutableArray *layerNames = [[NSMutableArray alloc] init];
//    for (NSDictionary *layerInfo in layerList) {
//        id layerId = [layerInfo objectForKey:@"id"];
//        NSString *layerName = [layerInfo objectForKey:@"name"];
//        if ([layerIds containsObject:layerId]) {
//            [layerNames addObject:layerName];
//            [_layerNameDic setObject:layerName forKey:layerId];
//        }
//    }
//    return layerNames;
//}

- (void)queryResultMonitor
{
//    NSLog(@"i am in");
    while ([_results count] < [_mapView.map.operationalLayers count]) {
        [NSThread sleepForTimeInterval:1.0];
//        NSLog(@"%ld/%ld", [_results count], [_mapView.SHPLayers count] + [_mapView.TILEDLayers count] + [_mapView.GDBLayers count], nil);
    }
    [self performSelectorOnMainThread:@selector(notifyQueryDone) withObject:nil waitUntilDone:YES];
}

- (void)queryResultCheckForLayers:(NSArray *)layers
{
    if(_results.count == [layers count])
    {
        [self notifyQueryDone];
    }
}

- (void)notifyQueryDone
{
//    [NSThread sleepForTimeInterval:5];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISQueryTool:didExecuteWithQueryResult:)]) {
        [self.delegate FZISQueryTool:self didExecuteWithQueryResult:_results];
    }
    
    [_results removeAllObjects];
}

- (void)stopSpatialQuery
{
    [_mapView.graphicsOverlays[0].graphics removeAllObjects];
    if (_lineView != nil) {
        [_lineView.points removeAllObjects];
        [_lineView removeFromSuperview];
    }
}

@end
