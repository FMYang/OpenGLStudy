//
//  GPUImageFramebuffer.m
//  GPUImage
//
//  Created by yfm on 2021/9/14.
//

#import "GPUImageFramebuffer.h"
#import "GPUImageOutput.h"

@interface GPUImageFramebuffer() {
    // 帧缓存的唯一ID
    GLuint framebuffer;
    
    // 渲染的目标
    CVPixelBufferRef renderTarget;
    // 渲染的纹理
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

@synthesize texture = _texture;

- (void)dealloc {
    [self destroyFramebuffer];
}

// 初始化方法
- (id)initWithSize:(CGSize)framebufferSize textureOptions:(GPUTextureOptions)fboTextureOptions {
    if(self = [super init]) {
        NSLog(@"fm create framebuffer");
        _size = framebufferSize;
        
        _textureOptions = fboTextureOptions;
        framebufferReferenceCount = 0;
        referenceCountingDisabled = NO;
        [self generateFramebuffer];
    }
    return self;
}

// 生成帧缓存和纹理
- (void)generateFramebuffer {
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        CVOpenGLESTextureCacheRef coreVideoTextureCache = [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache];
        
        // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
        
        CFDictionaryRef empty; // empty value for attr value.
        CFMutableDictionaryRef attrs;
        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);

        CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)_size.width, (int)_size.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
        if(err) {
            NSLog(@"FBO size: %f, %f", _size.width, _size.height);
            NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
        }
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           coreVideoTextureCache,
                                                           renderTarget,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           _textureOptions.internalFormat,
                                                           (int)_size.width,
                                                           (int)_size.height,
                                                           _textureOptions.format,
                                                           _textureOptions.type,
                                                           0,
                                                           &renderTexture);
        
        if(err) {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        CFRelease(attrs);
        CFRelease(empty);
        
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
        _texture = CVOpenGLESTextureGetName(renderTexture);
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
        
        // 将纹理附加到帧缓存
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
        
        #ifndef NS_BLOCK_ASSERTIONS
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        #endif
        
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyFramebuffer {
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if(framebuffer) {
            glDeleteFramebuffers(1, &framebuffer);
            framebuffer = 0;
        }
        
        if(renderTarget) {
            CFRelease(renderTarget);
            renderTarget = NULL;
        }
    });
}

#pragma mark - Usage

- (void)activateFramebuffer {
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)_size.width, (int)_size.height);
}

#pragma mark - 引用计数
- (void)lock {
    framebufferReferenceCount++;
}

- (void)unlock {
    framebufferReferenceCount--;
    if(framebufferReferenceCount < 1) {
        [[GPUImageContext sharedFramebufferCache] returnFramebufferToCache:self];
    }
}

- (void)clearAllLocks;
{
    framebufferReferenceCount = 0;
}

- (CVPixelBufferRef)pixelBuffer {
    return renderTarget;
}

- (GLuint)texture {
    return _texture;
}

@end
