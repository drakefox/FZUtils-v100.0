//
//  FZISGPSTool.h
//  FZISUtils
//
//  Created by fzis299 on 16/1/26.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@class FZISMapView;

@interface FZISGPSTool : NSObject
{
    __weak FZISMapView *_mapView;
}

- (FZISGPSTool *)initWithMapView:(FZISMapView *)mapView;

- (void)startLocationDisplay;
- (void)stopLocationDisplay;

@end
