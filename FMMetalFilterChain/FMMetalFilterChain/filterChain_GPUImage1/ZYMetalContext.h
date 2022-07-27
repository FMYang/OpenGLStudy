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

id<MTLCommandBuffer> render(id<MTLRenderPipelineState> pipelineState, id<MTLTexture> destinationTexture, id<MTLTexture> sourceTexture, float *vertices, float *textureCoordinate);

@interface ZYMetalContext : NSObject

@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) CVMetalTextureCacheRef textureCache;
@property (nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (nonatomic, readonly) id<MTLLibrary> library;
@property (nonatomic, readonly) ZYMetalFrameBufferCache *sharedFrameBufferCache;
@property (nonatomic, readonly) id<MTLRenderPipelineState> normalRenderPipelineState;

+ (ZYMetalContext *)shared;

@end

@protocol ZYMetalInput <NSObject>

- (void)setInputFramebuffer:(ZYMetalFrameBuffer *)newInputFramebuffer;
- (void)newFrameReadyAtTime:(CMTime)frameTime;

@end


NS_ASSUME_NONNULL_END
