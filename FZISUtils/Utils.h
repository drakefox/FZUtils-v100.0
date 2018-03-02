//
//  Utils.h
//  FZISMap
//
//  Created by fzis299 on 13-7-17.
//  Copyright (c) 2013年 FZIS. All rights reserved.
//

//#import "GDataXMLNode.h"

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <QuartzCore/QuartzCore.h>

#define kSurfix @"9527"
//#define kImageSizeWidth  (1024/7)
//#define kImageSizeHeigh  (748/7)

//#define kNativeMapConfig    @"NativeMapConfig"
//#define kTileOrigX          @"TileOrigX"
//#define kTileOrigY          @"TileOrigY"
//#define kMapOrigX           @"MapExtX"
//#define kMapOrigY           @"MapExtY"
//#define kInitRes            @"InitRes"
//#define kCoordType          @"CoordType"
//#define kTileUrl            @"tileUrl"
//#define kDLGLayer           @"DLGLayer"
//#define kDOMLayer           @"DOMLayer"

@interface Utils : NSObject

+ (NSString *)wifiMacAddress;
+ (NSString *)deviceSeries;
+ (BOOL)authorizateKey:(NSString *)activeCode bySeriesNo:(NSString *)seriesNo;


+ (BOOL)hasExperience;
+ (void)setHasExperience:(BOOL)experience;

+ (NSString *)expireTime;
+ (void)setExpireTime:(NSString *)expireTime;

+ (NSString *)checkPointTime;
+ (void)setCheckPointTime:(NSString *)checkPointTime;

+ (NSString *)usedTimes;
+ (void)setUsedTimes:(NSString *)usedTimes;

+ (NSString *)projType;
+ (void)setProjType:(NSString *)projType;

+ (NSString *)uuid;
+ (void)setUUID:(NSString *)uuid;

+ (BOOL)deviceAuthed;
+ (void)setDeviceAuthed:(BOOL)authed;


+ (NSDictionary *)getFolderSize:(NSString *)path;
+ (long long)folderSizeAtPath:(NSString *)folderPath;


@end
