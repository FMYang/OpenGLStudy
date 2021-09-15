//
//  GPUImageFramebufferCache.h
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import <Foundation/Foundation.h>
#import "GPUImageFramebuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageFramebufferCache : NSObject

- (GPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(GPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
- (void)returnFramebufferToCache:(GPUImageFramebuffer *)framebuffer;

@end

NS_ASSUME_NONNULL_END
