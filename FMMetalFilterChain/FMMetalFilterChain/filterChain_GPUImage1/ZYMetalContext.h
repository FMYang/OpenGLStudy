//
//  ZYMetalContext.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <MetalKit/MetalKit.h>

#import "ZYMetalFrameBuffer.h"
#import "ZYMetalFrameBufferCache.h"

NS_ASSUME_NONNULL_BEGIN

// 顶点坐标
static float normalVertices[] = { -1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0 };
// 纹理坐标
static float normalCoordinates[] = { 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0 };
static float flipHorizontallyCoordinates[] = { 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0 };
static float rotateCounterclockwiseCoordinates[] = { 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0 };

@interface ZYMetalContext : NSObject

@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) CVMetalTextureCacheRef textureCache;
@property (nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (nonatomic, readonly) id<MTLLibrary> library;
@property (nonatomic, readonly) ZYMetalFrameBufferCache *sharedFrameBufferCache;

+ (ZYMetalContext *)shared;

@end

@protocol ZYMetalInput <NSObject>

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputFramebuffer:(ZYMetalFrameBuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;

@end


NS_ASSUME_NONNULL_END
