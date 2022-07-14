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
#include "CameraShaderTypes.h"

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
        _device = MTLCreateSystemDefaultDevice();
        self.device = _device;
        
        static const FMVertex quadVertices[] = {
            // 顶点坐标, 纹理坐标
//            { { -1.0,  1.0 }, { 0.0, 0.0 } },
//            { {  1.0,  1.0 }, { 1.0, 0.0 } },
//            { { -1.0, -1.0 }, { 0.0, 1.0 } },
//            { {  1.0,  1.0 }, { 1.0, 0.0 } },
//            { { -1.0, -1.0 }, { 0.0, 1.0 } },
//            { {  1.0, -1.0 }, { 1.1, 1.1 } }
            
            { { -1.0,  1.0 },  { 0.0, 1.0 } },
            { {  1.0,  1.0 },  { 0.0, 0.0 } },
            { { -1.0, -1.0 },  { 1.0, 1.0 } },
            { {  1.0,  1.0 },  { 0.0, 0.0 } },
            { { -1.0, -1.0 },  { 1.0, 1.0 } },
            { {  1.0, -1.0 },  { 1.0, 0.0 } },
        };
        
        _vertices = [_device newBufferWithBytes:quadVertices
                                         length:sizeof(quadVertices)
                                        options:MTLResourceStorageModeShared];

        _numVertices = sizeof(quadVertices) / sizeof(FMVertex);

        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, _device, nil, &textureCacheRef);
        
        _commandQueue = [_device newCommandQueue];
        
        id<MTLLibrary> library = [_device newDefaultLibrary];
        id<MTLFunction> vextexFunction = [library newFunctionWithName:@"cameraVertex"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"cameraFrag"];
        
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.vertexFunction = vextexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;// HDR10
//        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm; // BGRA
        
        NSError *error;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];

        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);

    }
    return self;
}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if(self.currentRenderPassDescriptor == nil || self.currentDrawable == nil) return;
    
    float w = self.drawableSize.width;
    float h = self.drawableSize.height;
    
    _texture = [self loadTexture:pixelBuffer];

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    MTLRenderPassDescriptor *renderPassDescriptor = self.currentRenderPassDescriptor;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
    
    if(renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, w, h, -1.0, 1.0 }];

        // 使用这个渲染管线state对象来进行图元绘制
        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBuffer:_vertices
                                offset:0
                              atIndex:FMVertexInputIndexVertices];

        [renderEncoder setFragmentTexture:_texture
                                  atIndex:FMTextureIndexBaseColor];
        
        // 绘制顶点构成的图元
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:self.currentDrawable];
    } else {
        NSLog(@"renderPassDescriptor nil");
    }
    
    [commandBuffer commit];
}

- (id<MTLTexture>)loadTexture:(CVPixelBufferRef)pixcelBuffer {
    CVMetalTextureRef tmpTexture = NULL;
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                              textureCacheRef,
                                              pixcelBuffer,
                                              nil,
                                              MTLPixelFormatBGRA8Unorm_sRGB,
                                              CVPixelBufferGetWidth(pixcelBuffer),
                                              CVPixelBufferGetHeight(pixcelBuffer),
                                              0,
                                              &tmpTexture);
    id <MTLTexture> texture = CVMetalTextureGetTexture(tmpTexture);
    CFRelease(tmpTexture); // 释放创建的纹理
    return texture;
}

@end
