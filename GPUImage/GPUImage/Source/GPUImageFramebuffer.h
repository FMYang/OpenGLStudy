//
//  GPUImageFramebuffer.h
//  GPUImage
//
//  Created by yfm on 2021/9/14.
//
//  帧缓存对象，管理其附着的纹理和渲染缓存

#import <Foundation/Foundation.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct GPUTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} GPUTextureOptions;

@interface GPUImageFramebuffer : NSObject

// 帧缓存大小
@property(readonly) CGSize size;
// 纹理选项
@property(readonly) GPUTextureOptions textureOptions;
// 纹理唯一标识
@property(readonly) GLuint texture;

// 初始化帧缓存对象
- (id)initWithSize:(CGSize)framebufferSize textureOptions:(GPUTextureOptions)fboTextureOptions;

// 激活帧缓存
- (void)activateFramebuffer;

// 引用计数
- (void)lock;
- (void)unlock;
- (void)clearAllLocks;

// 原始数据
- (CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
