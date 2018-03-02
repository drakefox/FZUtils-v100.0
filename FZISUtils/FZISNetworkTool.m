//
//  FZISNetworkTool.m
//  FZISUtils
//
//  Created by fzis299 on 16/1/21.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import "FZISNetworkTool.h"
#import "Reachability.h"
#import "GlobeDefinitions.h"

@implementation FZISNetworkTool

@synthesize url;
@synthesize name;

- (FZISNetworkTool *)initWithURL:(NSString *)urlString
{
    self = [super init];
    if (self) {
        self.url = [NSURL URLWithString:urlString];
    }
    return self;
}

- (void)sendRequestByPOSTWithData:(NSData *)data
{
    if ([self isRemoteHostReachable]) {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url];
        [request setTimeoutInterval:10];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:data];
        __weak typeof(self) weakSelf = self;
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error != nil) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: error.localizedDescription};
                NSError *myError = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:networkRequestError userInfo:userInfo];
                if (strongSelf.delegate != nil && [strongSelf.delegate respondsToSelector:@selector(FZISNetworkTool:didGetError:)]) {
                    [strongSelf.delegate FZISNetworkTool:strongSelf didGetError:myError];
                }
            }
            else
            {
                if (strongSelf.delegate != nil && [strongSelf.delegate respondsToSelector:@selector(FZISNetworkTool:didGetResponse:withData:)]) {
                    [strongSelf.delegate FZISNetworkTool:strongSelf didGetResponse:response withData:data];
                }
            }
        }];
        [task resume];
    }
    else
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"网络连接失败！"};
        NSError *error = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:networkRequestError userInfo:userInfo];
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISNetworkTool:didGetError:)]) {
            [self.delegate FZISNetworkTool:self didGetError:error];
        }
    }
    
}

- (void)sendRequestByGET
{
    if ([self isRemoteHostReachable])
    {        
        __weak typeof(self) weakSelf = self;
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:self.url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (error != nil) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: error.localizedDescription};
                NSError *myError = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:networkRequestError userInfo:userInfo];
                if (strongSelf.delegate != nil && [strongSelf.delegate respondsToSelector:@selector(FZISNetworkTool:didGetError:)]) {
                    [strongSelf.delegate FZISNetworkTool:strongSelf didGetError:myError];
                }
            }
            else
            {
                if (strongSelf.delegate != nil && [strongSelf.delegate respondsToSelector:@selector(FZISNetworkTool:didGetResponse:withData:)]) {
                    [strongSelf.delegate FZISNetworkTool:strongSelf didGetResponse:response withData:data];
                }
            }
        }];
        [task resume];
    }
    else {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"网络连接失败！"};
        NSError *error = [NSError errorWithDomain:@"com.FZIS.FZISUtils.ErrorDomain" code:networkRequestError userInfo:userInfo];
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(FZISNetworkTool:didGetError:)]) {
            [self.delegate FZISNetworkTool:self didGetError:error];
        }
    }
}

- (BOOL)isRemoteHostReachable
{
    Reachability *r = [Reachability reachabilityWithHostName:url.host];
    
    if ([r currentReachabilityStatus] == NotReachable) {
//        NSLog(@"connection failed");
        return NO;
    }
    else
    {
//        NSLog(@"connection ok");
        return YES;
    }
}

@end
