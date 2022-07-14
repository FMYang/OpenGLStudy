//
//  ZYMetalDevice.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/14.
//

#import <Foundation/Foundation.h>
#include <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

// 顶点坐标
static float normalVertices[] = { -1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, -1.0 };
// 纹理坐标
static float normalCoordinates[] = { 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0 };
static float flipHorizontallyCoordinates[] = { 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0 };
static float rotateCounterclockwiseCoordinates[] = { 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0 };

@interface ZYMetalDevice : NSObject

+ (ZYMetalDevice *)shared;

@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) CVMetalTextureCacheRef textureCache;
@property (nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (nonatomic, readonly) id<MTLLibrary> library;

@end

NS_ASSUME_NONNULL_END
