//
//  GPUImageFramebuffer.m
//  GPUImage
//
//  Created by yfm on 2021/9/14.
//

#import "GPUImageFramebuffer.h"

@interface GPUImageFramebuffer() {
    // 帧缓存的唯一ID
    GLuint framebuffer;
    
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    NSUInteger readLockCount;
    
    NSUInteger framebufferReferenceCount;
    BOOL referenceCountingDisabled;
}

// 生成帧缓存
- (void)generateFramebuffer;
// 生成纹理
- (void)generateTexture;
// 释放帧缓存
- (void)destroyFramebuffer;

@end

@implementation GPUImageFramebuffer

// 初始化方法
- (id)initWithSize:(CGSize)framebufferSize textureOptions:(id)fboTextureOptions onlyTexture:(BOOL)onlyGenerateTexture {
    if(self = [super init]) {
        _size = framebufferSize;
        framebufferReferenceCount = 0;
        referenceCountingDisabled = NO;
        _missingFramebuffer = onlyGenerateTexture;
        
        if(_missingFramebuffer) {
            
        }
    }
    return self;
}

@end
