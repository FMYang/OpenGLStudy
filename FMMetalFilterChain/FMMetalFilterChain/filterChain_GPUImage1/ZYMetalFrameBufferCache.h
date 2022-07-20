//
//  ZYMetalFrameBufferCache.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//

#import <Foundation/Foundation.h>
#import "ZYMetalFrameBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYMetalFrameBufferCache : NSObject

- (ZYMetalFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize;
- (void)returnFramebufferToCache:(ZYMetalFrameBuffer *)framebuffer;

@end

NS_ASSUME_NONNULL_END
