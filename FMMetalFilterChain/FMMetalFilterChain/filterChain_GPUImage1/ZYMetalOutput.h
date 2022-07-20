//
//  ZYMetalOutput.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//

#import <Foundation/Foundation.h>
#import "ZYMetalFrameBuffer.h"
#import "ZYMetalContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYMetalOutput : NSObject {
    ZYMetalFrameBuffer *outputFramebuffer;
    NSMutableArray *targets;
    CGSize inputTextureSize;
}

- (void)addTarget:(id<ZYMetalInput>)newTarget;
- (void)removeTarget:(id<ZYMetalInput>)targetToRemove;

- (ZYMetalFrameBuffer *)framebufferForOutput;
- (void)removeOutputFramebuffer;
- (void)setInputFramebufferForTarget:(id<ZYMetalInput>)target atIndex:(NSInteger)inputTextureIndex;

@end

NS_ASSUME_NONNULL_END
