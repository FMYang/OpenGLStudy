//
//  ZYMPSFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/14.
//

#import "ZYMPSFilter.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@implementation ZYMPSFilter

- (id<MTLRenderCommandEncoder>)encodeMetalCommand:(id<MTLCommandBuffer>)commandBuffer
                                    pipelineState:(id<MTLRenderPipelineState>)pipelineState
                                     inputTexture:(id<MTLTexture>)inputTexture
                                    outputTexture:(id<MTLTexture>)outputTexture
                                           device:(nonnull id<MTLDevice>)device {
    MPSImageGaussianBlur *kernel =
        [[MPSImageGaussianBlur alloc] initWithDevice:device sigma:10.0];
    [kernel encodeToCommandBuffer:commandBuffer sourceTexture:inputTexture destinationTexture:outputTexture];

    return nil;
//    MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
//    renderPassDescriptor.colorAttachments[0].texture = outputTexture;
//    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
//    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
//    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
//
//    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
//    [commandEncoder setRenderPipelineState:pipelineState];
//
//    id<MTLBuffer> positionBuffer = [device newBufferWithBytes:normalVertices length:sizeof(normalVertices) options:MTLResourceStorageModeShared];
//    id<MTLBuffer> texCoordinateBuffer = [device newBufferWithBytes:normalCoordinates length:sizeof(normalCoordinates) options:MTLResourceStorageModeShared];
//
//    [commandEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];
//    [commandEncoder setVertexBuffer:texCoordinateBuffer offset:0 atIndex:1];
//    [commandEncoder setFragmentTexture:outputTexture atIndex:0];
//
//    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
//
//    return commandEncoder;
}

- (NSString *)functionName {
    return @"mpsFragmentShader";
}

@end
