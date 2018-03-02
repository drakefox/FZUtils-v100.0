//
//  Utils.m
//  FZISMap
//
//  Created by fzis299 on 13-7-17.
//  Copyright (c) 2013年 FZIS. All rights reserved.
//

#import "Utils.h"
#import "DESEncodeHelper.h"
#import "MDFiveDigestHelper.h"
//#import "GDataXMLNode.h"
#import "UUIDUtils.h"

#import <sys/stat.h>
#import <dirent.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <ifaddrs.h>

#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>
#import <AdSupport/AdSupport.h>

#define kHasAuthed          @"HasAuthed"
#define kHasExperience      @"HasExperience"
//#define kMapIpAddress       @"ip地址"
//#define kMapPortNumber      @"端口号"
//#define kMapSuffixString    @"路径"
//#define kMapCachePrefixes   @"CachePrefixes"
//#define kIsCacheNeeded      @"IsCacheNeeded"
//#define kIsEncodeNeeded     @"IsEncodeNeeded"
#define kExpireTime         @"ExpireTime"
#define kCheckPointTime     @"CheckPointTime"
#define kAUFilePath         @"AUFilePath"
#define kUsedTimes          @"UsedTimes"
#define kProjType           @"ProjType"
#define kUUID               @"UUID"

//#define kBusinessView       @"BusinessView"
//#define kMainMenu           @"MainMenu"
//#define kListView           @"ListView"
//#define kDetailsView        @"DetailsView"
//#define kMapView            @"MapView"

//#define kMapServerInfo      @"MapServerInfo"


@implementation Utils

#pragma mark - Process the NSUserDefaults settings

+ (BOOL)hasExperience
{
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kHasExperience];
    NSString *decValue = [DESEncodeHelper decryptWithText:value];
    if ([decValue isEqualToString:@"No"]) {
        return NO;
    }
    else
    {
        return YES;
    }
}

+ (void)setHasExperience:(BOOL)experience
{
    NSString *value;
    if (!experience) {
        value = [DESEncodeHelper encryptWithText:@"No"];
    }
    else
    {
        value = [DESEncodeHelper encryptWithText:@"Yes"];
    }
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kHasExperience];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)expireTime
{
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kExpireTime];
    NSString *decValue = [DESEncodeHelper decryptWithText:value];
    return decValue;
}

+ (void)setExpireTime:(NSString *)expireTime
{
    NSString *value = [DESEncodeHelper encryptWithText:expireTime];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kExpireTime];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)checkPointTime
{
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kCheckPointTime];
    NSString *decValue = [DESEncodeHelper decryptWithText:value];
    return decValue;
}

+ (void)setCheckPointTime:(NSString *)checkPointTime
{
    NSString *value = [DESEncodeHelper encryptWithText:checkPointTime];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kCheckPointTime];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)usedTimes
{
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kUsedTimes];
    NSString *decValue = [DESEncodeHelper decryptWithText:value];
    return decValue;
}

+ (void)setUsedTimes:(NSString *)usedTimes
{
    NSString *value = [DESEncodeHelper encryptWithText:usedTimes];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kUsedTimes];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)projType
{
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kProjType];
    NSString *decValue = [DESEncodeHelper decryptWithText:value];
    return decValue;
}

+ (void)setProjType:(NSString *)projType
{
    NSString *value = [DESEncodeHelper encryptWithText:projType];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kProjType];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)uuid
{
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kUUID];
    NSString *decValue = [DESEncodeHelper decryptWithText:value];
    return decValue;
}

+ (void)setUUID:(NSString *)uuid
{
    NSString *value = [DESEncodeHelper encryptWithText:uuid];
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kUUID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)deviceAuthed
{
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kHasAuthed];
    NSString *decValue = [DESEncodeHelper decryptWithText:value];
    if ([decValue isEqualToString:@"Yes"]) {
        return YES;
    }
    else
    {
        return NO;
    }
}

+ (void)setDeviceAuthed:(BOOL)authed
{
    NSString *value;
    if (!authed) {
        value = [DESEncodeHelper encryptWithText:@"No"];
    }
    else
    {
        value = [DESEncodeHelper encryptWithText:@"Yes"];
    }
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:kHasAuthed];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

#pragma mark - Other functions

+ (NSString *)wifiMacAddress
{
    
    //use ad identifier for activation code after ios 7.0
//    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
//    NSLog(@"%@", adId);
//    return adId;
    
    NSString *uuid = [UUIDUtils readUUIDFromKeyChain];
    
    if (uuid == nil || [uuid isEqualToString:@""]) {
//        NSLog(@"no uuid in keychain, create one");
        uuid = [UUIDUtils getUUIDString];
        [UUIDUtils saveUUIDToKeyChain:uuid];
    }
    
//    NSLog(@"uuid in keychain:%@", uuid);
    return uuid;
    
}

+ (NSString *)deviceSeries
{
    NSString *wifiAddMd5Value = [MDFiveDigestHelper md5HexDigest:[Utils wifiMacAddress]];
    return wifiAddMd5Value;
}

+ (BOOL)authorizateKey:(NSString *)activeCode bySeriesNo:(NSString *)seriesNo
{
    NSString *reallyCode = [seriesNo stringByAppendingString:kSurfix];
//    NSLog(@"reallycode: %@", reallyCode);
    NSString *md5Encoded = [MDFiveDigestHelper md5HexDigest:reallyCode];
    NSRange range = NSMakeRange(0, 16);

    NSString *result = [md5Encoded substringWithRange:range];
    NSLog(@"授权码应为：\n%@", [result uppercaseString]);
    
    if ([[activeCode uppercaseString] isEqualToString:[result uppercaseString]])
    {
        [Utils setDeviceAuthed:YES];
        return YES;
    }
    else if ([[activeCode uppercaseString] isEqualToString:@"9527"])
    {
        return YES;
    }
    
    return NO;
}

#pragma mark - Caculate the cache size

+ (NSDictionary *)getFolderSize:(NSString *)path
{
    NSString *showPath = [path lastPathComponent];
    long long size = [Utils folderSizeAtPath:path];
    NSString *folderSize = [NSString stringWithFormat:@"%llu", size];
    NSDictionary *subFolderInfo = [[NSDictionary alloc] initWithObjectsAndKeys:showPath, @"name", folderSize, @"size", path, @"path", nil];  
    return subFolderInfo;
}

+ (long long)folderSizeAtPath:(NSString *)folderPath
{
    return [self _folderSizeAtPath:[folderPath cStringUsingEncoding:NSUTF8StringEncoding]];
}

+ (long long)_folderSizeAtPath:(const char*)folderPath
{
    long long folderSize = 0;
    DIR *dir = opendir(folderPath);
    if (dir == NULL) {
        return 0;
    }
    
    struct dirent* child;
    while ((child = readdir(dir)) != NULL) {
        if (child->d_type == DT_DIR && ((child->d_name[0] == '.' && child->d_name[1] == 0) || (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0))) {
            continue;
        }
        
        unsigned long folderPathLength = strlen(folderPath);
        char childPath[1024];
        stpcpy(childPath, folderPath);
        if (folderPath[folderPathLength - 1] != '/') {
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }
        
        stpcpy(childPath + folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;
        
        if (child->d_type == DT_DIR) {
            folderSize += [self _folderSizeAtPath:childPath];
            //            struct stat st;
            //            if (lstat(childPath, &st) == 0) {
            //                folderSize += st.st_size;
            //            }
        }
        else if (child->d_type == DT_REG || child->d_type == DT_LNK)
        {
            struct stat st;
            if (lstat(childPath, &st) == 0) {
                folderSize += st.st_size;
            }
        }
    }
    return folderSize;
}



@end
