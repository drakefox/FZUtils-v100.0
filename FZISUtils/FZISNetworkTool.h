//
//  FZISNetworkTool.h
//  FZISUtils
//
//  Created by fzis299 on 16/1/21.
//  Copyright (c) 2016年 FZIS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FZISNetworkToolDelegate;

@interface FZISNetworkTool : NSObject
{
    
}
@property (nonatomic, retain) NSString *name;

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, weak) id<FZISNetworkToolDelegate> delegate;

- (FZISNetworkTool *)initWithURL:(NSString *)url;
- (void)sendRequestByPOSTWithData:(NSData *)data;
- (void)sendRequestByGET;


@end

@protocol FZISNetworkToolDelegate <NSObject>

@optional

- (void)FZISNetworkTool:(FZISNetworkTool *)networkTool didGetResponse:(NSURLResponse *)response withData:(NSData *)data;
- (void)FZISNetworkTool:(FZISNetworkTool *)networkTool didGetError:(NSError *)error;

@end
