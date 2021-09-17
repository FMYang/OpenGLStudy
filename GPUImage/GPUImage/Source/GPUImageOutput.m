//
//  GPUImageOutput.m
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import "GPUImageContext.h"

void runSynchronouslyOnVideoProcessingQueue(void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [GPUImageContext sharedContextQueue];
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
    if (dispatch_get_specific([GPUImageContext contextKey]))
#endif
    {
        block();
    }else
    {
        dispatch_sync(videoProcessingQueue, block);
    }
}

void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [GPUImageContext sharedContextQueue];
    
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
    if (dispatch_get_specific([GPUImageContext contextKey]))
#endif
    {
        block();
    }else
    {
        dispatch_async(videoProcessingQueue, block);
    }
}

#import "GPUImageOutput.h"

@implementation GPUImageOutput

- (instancetype)init {
    if(self = [super init]) {
        targets = [[NSMutableArray alloc] init];
        targetTextureIndices = [[NSMutableArray alloc] init];
        
        // set default texture options
        _outputTextureOptions.minFilter = GL_LINEAR;
        _outputTextureOptions.magFilter = GL_LINEAR;
        _outputTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
        _outputTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
        _outputTextureOptions.internalFormat = GL_RGBA;
        _outputTextureOptions.format = GL_BGRA;
        _outputTextureOptions.type = GL_UNSIGNED_BYTE;
    }
    return self;
}

#pragma mark - Managing targets
- (void)setInputFramebufferForTarget:(id<GPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
{
    [target setInputFramebuffer:[self framebufferForOutput] atIndex:inputTextureIndex];
}

- (GPUImageFramebuffer *)framebufferForOutput;
{
    return outputFramebuffer;
}

- (void)removeOutputFramebuffer {
    outputFramebuffer = nil;
}

- (void)addTarget:(id<GPUImageInput>)newTarget {
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self addTarget:newTarget atTextureLocation:nextAvailableTextureIndex];
}

- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation {
    if([targets containsObject:newTarget]) {
        return;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [self setInputFramebufferForTarget:newTarget atIndex:textureLocation];

        [targets addObject:newTarget];
        [targetTextureIndices addObject:[NSNumber numberWithInteger:textureLocation]];
    });
}

- (void)removeTarget:(id<GPUImageInput>)targetToRemove {
    if(![targets containsObject:targetToRemove]) {
        return;
    }
    
    NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
    NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [targetTextureIndices removeObjectAtIndex:indexOfObject];
        [targets removeObject:targetToRemove];
        [targetToRemove endProcessing];
    });
}

@end
