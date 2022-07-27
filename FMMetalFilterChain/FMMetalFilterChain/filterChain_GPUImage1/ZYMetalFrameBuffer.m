//
//  ZYMetalFrameBuffer.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//

#import "ZYMetalFrameBuffer.h"
#import "ZYMetalContext.h"

@interface ZYMetalFrameBuffer() {
    CVPixelBufferRef renderTarget;
    CVMetalTextureRef renderTexture;
    NSUInteger framebufferReferenceCount;
    NSLock *_lock;
}

@end

@implementation ZYMetalFrameBuffer
@synthesize size = _size;
@synthesize texture = _texture;

- (void)dealloc {
    [self destroyFramebuffer];
}

- (id)initWithSize:(CGSize)framebufferSize {
    if(!(self = [super init])) {
        return nil;
    }
    
    _lock = [[NSLock alloc] init];
    framebufferReferenceCount = 0;
    _size = framebufferSize;
    [self generateTexture];

    return self;
}

- (void)generateTexture {
    // 创建一个null的pixelbuffer与outputTexture绑定
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);

    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault, _size.width, _size.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
    NSAssert(result == kCVReturnSuccess, @"create pixel failed");
    CFRelease(attrs);
    CFRelease(empty);

    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, ZYMetalContext.shared.textureCache, renderTarget, nil, MTLPixelFormatBGRA8Unorm, _size.width, _size.height, 0, &renderTexture);
    
    _texture = CVMetalTextureGetTexture(renderTexture);
}

- (void)lock {
    [_lock lock];
    framebufferReferenceCount++;
    [_lock unlock];
}

- (void)unlock {
    [_lock lock];
    framebufferReferenceCount--;

    if(framebufferReferenceCount < 1) {
        [self save];
    }
    [_lock unlock];
}

- (void)save {
    [ZYMetalContext.shared.sharedFrameBufferCache returnFramebufferToCache:self];
}

- (void)destroyFramebuffer {
    if(renderTarget) {
        CFRelease(renderTarget);
        renderTarget = NULL;
    }
    
    if(renderTexture) {
        CFRelease(renderTexture);
        renderTexture = NULL;
    }
}

- (CVPixelBufferRef)pixelBuffer {
    return renderTarget;
}

- (id<MTLTexture>)texture {
    return _texture;
}

@end
