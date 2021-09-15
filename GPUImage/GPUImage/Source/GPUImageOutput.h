//
//  GPUImageOutput.h
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import "GPUImageContext.h"
#import "GPUImageFramebuffer.h"
#import <UIKit/UIKit.h>

dispatch_queue_attr_t GPUImageDefaultQueueAttribute(void);
void runOnMainQueueWithoutDeadlocking(void (^block)(void));
void runSynchronouslyOnVideoProcessingQueue(void (^block)(void));
void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void));
void runSynchronouslyOnContextQueue(GPUImageContext *context, void (^block)(void));
void runAsynchronouslyOnContextQueue(GPUImageContext *context, void (^block)(void));
void reportAvailableMemoryForGPUImage(NSString *tag);

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageOutput : NSObject {
    GPUImageFramebuffer *outputFramebuffer;
    
    NSMutableArray *targets, *targetTextureIndices;
}

@property(readwrite, nonatomic) GPUTextureOptions outputTextureOptions;

- (void)addTarget:(id<GPUImageInput>)newTarget;
- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
- (void)removeTarget:(id<GPUImageInput>)targetToRemove;
- (void)removeAllTargets;

@end

NS_ASSUME_NONNULL_END
