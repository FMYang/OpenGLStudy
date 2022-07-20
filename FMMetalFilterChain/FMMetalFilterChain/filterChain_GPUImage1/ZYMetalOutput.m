//
//  ZYMetalOutput.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//

#import "ZYMetalOutput.h"

@implementation ZYMetalOutput

- (instancetype)init {
    if(self = [super init]) {
        targets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setInputFramebufferForTarget:(id<ZYMetalInput>)target atIndex:(NSInteger)inputTextureIndex {
    [target setInputFramebuffer:[self framebufferForOutput] atIndex:inputTextureIndex];
}

- (ZYMetalFrameBuffer *)framebufferForOutput {
    return outputFramebuffer;
}

- (void)removeOutputFramebuffer {
    outputFramebuffer = nil;
}

- (void)addTarget:(id<ZYMetalInput>)newTarget {
    if([targets containsObject:newTarget]) {
        return;
    }
    [targets addObject:newTarget];
}

- (void)removeTarget:(id<ZYMetalInput>)targetToRemove {
    if(![targets containsObject:targetToRemove]) {
        return;
    }
    [targets removeObject:targetToRemove];
}

@end
