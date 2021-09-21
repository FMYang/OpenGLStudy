//
//  FMFrameBuffer.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/20.
//

#import "FMFrameBuffer.h"
#import "FMCameraContext.h"

@interface FMFrameBuffer() {
    GLuint framebuffer;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    
    CGSize bufferSize;
}

@end

@implementation FMFrameBuffer

@synthesize texture = _texture;

- (id)initWithSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture {
    if(self = [super init]) {
        bufferSize = framebufferSize;
        
        if(onlyTexture) {
            [self generateTexture];
            framebuffer = 0;
        } else {
            [self generateFramebuffer];
        }
    }
    return self;
}

- (void)activateFramebuffer {
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)bufferSize.width, (int)bufferSize.height);
}

- (void)generateTexture {
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // This is necessary for non-power-of-two textures
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
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

    // 创建目标纹理，并与目标pixelBuffer关联起来，pixelBuffer和纹理共享缓存，纹理上绘制的内容，通过pixelBuffer可以获取到
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
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    _texture = CVOpenGLESTextureGetName(renderTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
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
