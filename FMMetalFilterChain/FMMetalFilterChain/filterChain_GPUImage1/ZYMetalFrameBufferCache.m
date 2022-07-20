//
//  ZYMetalFrameBufferCache.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//

#import "ZYMetalFrameBufferCache.h"

@interface ZYMetalFrameBufferCache() {
    NSMutableDictionary *framebufferCache;
}
@end

@implementation ZYMetalFrameBufferCache

- (instancetype)init {
    if(self = [super init]) {
        framebufferCache = @{}.mutableCopy;
    }
    return self;
}

- (NSString *)hashForSize:(CGSize)size {
    return [NSString stringWithFormat:@"%.1fx%.1f", size.width, size.height];
}

- (ZYMetalFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize {
    NSString *lookupHash = [self hashForSize:framebufferSize];
    ZYMetalFrameBuffer *frameBuffer = [framebufferCache objectForKey:lookupHash];
    if(frameBuffer == nil) {
//        NSLog(@"没有缓存");
        frameBuffer = [[ZYMetalFrameBuffer alloc] initWithSize:framebufferSize];
        [framebufferCache setObject:frameBuffer forKey:lookupHash];
    } else {
//        NSLog(@"有缓存");
        return [framebufferCache objectForKey:lookupHash];
    }
    
    return frameBuffer;
}

- (void)returnFramebufferToCache:(ZYMetalFrameBuffer *)framebuffer {
    
}

@end
