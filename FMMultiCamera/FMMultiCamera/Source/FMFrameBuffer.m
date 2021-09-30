//
//  FMFrameBuffer.m
//  FMMultiCamera
//
//  Created by yfm on 2021/9/29.
//

#import "FMFrameBuffer.h"
#import "FMCameraContext.h"

@implementation FMFrameBuffer {
    GLuint framebuffer;
    GLuint _texture;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    CGSize bufferSize;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    [FMCameraContext useImageProcessingContext];
    if(framebuffer) {
        glDeleteFramebuffers(1, &framebuffer);
        framebuffer = 0;
    }
    if(renderTarget) {
        CVPixelBufferRelease(renderTarget);
        renderTarget = NULL;
    }
    if(renderTexture) {
        CFRelease(renderTexture);
        renderTexture = NULL;
    }
}

- (instancetype)initWithSize:(CGSize)frameBufferSize {
    if(self = [super init]) {
        bufferSize = frameBufferSize;
        [self generateFramebuffer];
    }
    return self;
}

- (void)activateFramebuffer {
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)bufferSize.width, (int)bufferSize.height);
}

- (void)generateFramebuffer {
    [FMCameraContext useImageProcessingContext];

    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

    CVOpenGLESTextureCacheRef coreVideoTextureCache = [[FMCameraContext shared] coreVideoTextureCache];
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)bufferSize.width, (int)bufferSize.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
    
    if (err)
    {
        NSLog(@"FBO size: %f, %f", bufferSize.width, bufferSize.height);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }

    // 创建目标纹理，并与目标pixelBuffer绑定，pixelBuffer和纹理共享缓存，纹理上绘制的内容，通过pixelBuffer可以获取到
    /**
     https://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
     相比glReadPixels（读取速度慢，性能瓶颈），CVOpenGLESTextureCache可以更快速的获取到纹理上的原始数据
     */
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                        coreVideoTextureCache,
                                                        renderTarget,
                                                        NULL,
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA,
                                                        (int)bufferSize.width,
                                                        (int)bufferSize.height,
                                                        GL_BGRA,
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &renderTexture);
    if (err) {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    _texture = CVOpenGLESTextureGetName(renderTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 将纹理附加到帧缓冲区
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);

    glBindTexture(GL_TEXTURE_2D, 0);
}

- (CVPixelBufferRef)pixelBuffer {
    return renderTarget;
}

- (GLuint)texture {
    return _texture;
}

@end
