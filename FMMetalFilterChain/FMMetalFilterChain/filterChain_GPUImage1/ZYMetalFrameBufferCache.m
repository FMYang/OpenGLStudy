//
//  ZYMetalFrameBufferCache.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//
//  管理离屏缓存

#import "ZYMetalFrameBufferCache.h"

@interface ZYMetalFrameBufferCache() {
    NSMutableDictionary *_framebufferCache;
    NSLock *_lock;
}
@end

@implementation ZYMetalFrameBufferCache

- (instancetype)init {
    if(self = [super init]) {
        _framebufferCache = @{}.mutableCopy;
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (NSString *)hashForSize:(CGSize)size {
    return [NSString stringWithFormat:@"%.1fx%.1f", size.width, size.height];
}

- (ZYMetalFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize {
    [_lock lock];
    NSString *lookupHash = [self hashForSize:framebufferSize];
    ZYMetalFrameBuffer *frameBuffer = [_framebufferCache objectForKey:lookupHash];
    if(frameBuffer == nil) {
        // 缓存里没有创建一个
        frameBuffer = [[ZYMetalFrameBuffer alloc] initWithSize:framebufferSize];
    } else {
        // 取缓存的
        frameBuffer = [_framebufferCache objectForKey:lookupHash];
        [_framebufferCache removeObjectForKey:lookupHash];
    }
    [frameBuffer lock];
    [_lock unlock];
    return frameBuffer;
}

- (void)returnFramebufferToCache:(ZYMetalFrameBuffer *)framebuffer {
    [_lock lock];
    NSString *lookupHash = [self hashForSize:framebuffer.size];
    [_framebufferCache setObject:framebuffer forKey:lookupHash];
    [_lock unlock];
}

@end
