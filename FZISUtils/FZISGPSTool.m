//
//  FZISGPSTool.m
//  FZISUtils
//
//  Created by fzis299 on 16/1/26.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import "FZISGPSTool.h"
#import "FZISMapView.h"

@implementation FZISGPSTool

- (FZISGPSTool *)initWithMapView:(FZISMapView *)mapView
{
    self = [super init];
    if (self) {
        _mapView = mapView;
        _mapView.locationDisplay.wanderExtentFactor = 0;
        _mapView.locationDisplay.initialZoomScale = 2000.0;
    }
    
    return self;
}

- (void)startLocationDisplay
{
    _mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeCompassNavigation;
    if (![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] ==  kCLAuthorizationStatusRestricted || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"当前无法访问定位服务，请确认定位服务已打开并授权本应用使用。"};
        NSError *error = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:locationDisplayError userInfo:userInfo];
        if (_mapView.operationHandler != nil && [_mapView.operationHandler respondsToSelector:@selector(operationFailedWithError:)]) {
            [_mapView.operationHandler operationFailedWithError:error];
        }
    }
    else {
        __weak typeof(self) weakSelf = self;
        [_mapView.locationDisplay startWithCompletion:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error != nil) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: error.localizedDescription};
                NSError *myError = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:locationDisplayError userInfo:userInfo];
                if (strongSelf->_mapView.operationHandler != nil && [strongSelf->_mapView.operationHandler respondsToSelector:@selector(operationFailedWithError:)]) {
                    [strongSelf->_mapView.operationHandler operationFailedWithError:myError];
                }
            }
            else {
//                NSLog(@"%ld",(long)_mapView.locationDisplay.autoPanMode, nil);
                [strongSelf->_mapView setViewpointScale:2000.0 completion:nil];
            }
        }];
    }
}

- (void)stopLocationDisplay
{
    [_mapView.locationDisplay stop];
}

@end
