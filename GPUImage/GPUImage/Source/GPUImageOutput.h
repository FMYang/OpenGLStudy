//
//  GPUImageOutput.h
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import "GPUImageContext.h"
#import "GPUImageFramebuffer.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

void runSynchronouslyOnVideoProcessingQueue(void (^block)(void));
void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void));

@interface GPUImageOutput : NSObject {
    GPUImageFramebuffer *outputFramebuffer;
    
    NSMutableArray *targets, *targetTextureIndices;
    
    CGSize inputTextureSize;
}

@property(readwrite, nonatomic) GPUTextureOptions outputTextureOptions;

- (void)addTarget:(id<GPUImageInput>)newTarget;
- (void)addTarget:(id<GPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
- (void)removeTarget:(id<GPUImageInput>)targetToRemove;

- (GPUImageFramebuffer *)framebufferForOutput;
- (void)removeOutputFramebuffer;
- (void)setInputFramebufferForTarget:(id<GPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;

@end

NS_ASSUME_NONNULL_END
