//
//  FMMetalCameraView.m
//  LearnMetal
//
//  Created by yfm on 2021/10/17.
//

#import "FMMetalCameraView.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#include <simd/simd.h>

typedef struct {
    vector_float2 position;
    vector_float2 textureCoordinate;
} FMVertex;

@interface FMMetalCameraView() {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLTexture> _texture;
    id<MTLBuffer> _vertices;
    NSUInteger _numVertices;
    CVMetalTextureCacheRef textureCacheRef;
    vector_uint2 _viewportSize;
}

@end

@implementation FMMetalCameraView

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        static const FMVertex quadVertices[] = {
            // 顶点坐标, 纹理坐标
            { {  -1.0,  1.0 },  { 0.0, 0.0 } },
            { { 1.0,  1.0 },  { 1.0, 0.0 } },
            { { -1.0,   -1.0 },  { 0.0, 1.0 } },

            { {  1.0,  1.0 },  { 1.0, 0.0 } },
            { { -1.0,   -1.0 },  { 0.0, 1.0 } },
            { {  1.0,   -1.0 },  { 1.1, 1.1 } },
            
//            // 右旋转90度，3.jpeg
//            { {  -1.0,  1.0 },  { 0.0, 1.0 } },
//            { { 1.0,  1.0 },  { 0.0, 0.0 } },
//            { { -1.0,   -1.0 },  { 1.0, 1.0 } },
//
//            { {  1.0,  1.0 },  { 0.0, 0.0 } },
//            { { -1.0,   -1.0 },  { 1.0, 1.0 } },
//            { {  1.0,   -1.0 },  { 1.0, 0.0 } },
        };
        
        _vertices = [_device newBufferWithBytes:quadVertices
                                         length:sizeof(quadVertices)
                                        options:MTLResourceStorageModeShared];

        _numVertices = sizeof(quadVertices) / sizeof(FMVertex);

        _device = MTLCreateSystemDefaultDevice();
        self.device = _device;
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, _device, nil, &textureCacheRef);
        
        _commandQueue = [_device newCommandQueue];
        
        id<MTLLibrary> library = [_device newDefaultLibrary];
        id<MTLFunction> vextexFunction = [library newFunctionWithName:@"cameraVertex"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"cameraFrag"];
        
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.vertexFunction = vextexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        
        NSError *error;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];

        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);

    }
    return self;
}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    _texture = [self loadTexture:pixelBuffer];

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    MTLRenderPassDescriptor *renderPassDescriptor = self.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

        // 使用这个渲染管线state对象来进行图元绘制
        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBuffer:_vertices
                                offset:0
                              atIndex:0];

        [renderEncoder setFragmentTexture:_texture
                                  atIndex:0];
        
        // 绘制顶点构成的图元
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:self.currentDrawable];
    }

    [commandBuffer commit];

}

// 通过MTKTextureLoader加载纹理
- (id<MTLTexture>)loadTexture:(CVPixelBufferRef)pixcelBuffer {
    CVMetalTextureRef textureRef;
    float bufferW = CVPixelBufferGetWidth(pixcelBuffer);
    float bufferH = CVPixelBufferGetHeight(pixcelBuffer);
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCacheRef, pixcelBuffer, nil, MTLPixelFormatRG8Unorm, bufferW, bufferH, 0, &textureRef);
    id <MTLTexture> texture = CVMetalTextureGetTexture(textureRef);
    return texture;
}


#pragma mark - MTKViewDelegate
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

@end
