//
//  GlobeDefinitions.h
//  FZISUtils
//
//  Created by fzis299 on 2017/7/21.
//  Copyright © 2017年 FZIS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    statusNormal = 0,
    statusMeasureDistance,
    statusMeasureDistanceEnd,
    statusMeasureArea,
    statusMeasureAreaEnd,
    statusSandbox
}FZISMapViewStatus;

typedef enum {
    loadGeodatabaseError = 0,
    loadBasemapError,
    locationDisplayError,
    networkRequestError,
    identifyOperationError
}FZISMapViewErrorCode;

@interface GlobeDefinitions : NSObject

@end
