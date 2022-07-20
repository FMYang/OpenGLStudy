//
//  ZYMetalFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import "ZYMetalFilter.h"

@interface ZYMetalFilter() {
    id<MTLTexture> inputTexture;
    NSString *fragmentFunction;
}

@end

@implementation ZYMetalFilter

- (id)initWithFragmentFunction:(NSString *)function {
    if(self = [super init]) {
        fragmentFunction = function;
    }
    return self;
}

// 第一步：将相机输出帧，写入离屏纹理（outputFramebuffer）
- (void)push:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime {
    CVMetalTextureRef texture = nil;
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, ZYMetalContext.shared.textureCache, pixelBuffer, nil, MTLPixelFormatBGRA8Unorm, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 0, &texture);
    CGSize size = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    outputFramebuffer = [ZYMetalContext.shared.sharedFrameBufferCache fetchFramebufferForSize:size];

    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    renderPipelineDescriptor.vertexFunction = [ZYMetalContext.shared.library newFunctionWithName:@"normalVertex"];
    renderPipelineDescriptor.fragmentFunction = [ZYMetalContext.shared.library newFunctionWithName:@"normalFragmentShader"];

    id<MTLRenderPipelineState> renderPipelineState = [ZYMetalContext.shared.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:nil];
    id<MTLCommandBuffer> commandBuffer = [ZYMetalContext.shared.commandQueue commandBuffer];
    
    {
        MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        renderPassDescriptor.colorAttachments[0].texture = outputFramebuffer.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [commandEncoder setRenderPipelineState:renderPipelineState];

        id<MTLBuffer> positionBuffer = [ZYMetalContext.shared.device newBufferWithBytes:normalVertices length:sizeof(normalVertices) options:MTLResourceStorageModeShared];
        id<MTLBuffer> texCoordinateBuffer = [ZYMetalContext.shared.device newBufferWithBytes:normalCoordinates length:sizeof(normalCoordinates) options:MTLResourceStorageModeShared];
        
        [commandEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBuffer:texCoordinateBuffer offset:0 atIndex:1];
        [commandEncoder setFragmentTexture:CVMetalTextureGetTexture(texture) atIndex:0];

        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        
        [commandEncoder endEncoding];
    }
    
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
        
    CFRelease(texture);
    
    // 第二步：开始滤镜链调用
    [self setInputFramebuffer:outputFramebuffer atIndex:0];
    [self newFrameReadyAtTime:frameTime atIndex:0];
}

- (CGSize)sizeOfFBO {
    return CGSizeMake(inputTexture.width, inputTexture.height);
}

// 第三部：子类滤镜逐个调用setInputFramebuffer: 和 newFrameReadyAtTime:
- (void)setInputFramebuffer:(ZYMetalFrameBuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    inputTexture = newInputFramebuffer.texture;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    outputFramebuffer = [ZYMetalContext.shared.sharedFrameBufferCache fetchFramebufferForSize:[self sizeOfFBO]];
    
    NSError *error = nil;
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    renderPipelineDescriptor.vertexFunction = [ZYMetalContext.shared.library newFunctionWithName:@"normalVertex"];
    renderPipelineDescriptor.fragmentFunction = [ZYMetalContext.shared.library newFunctionWithName:fragmentFunction];

    id<MTLRenderPipelineState> renderPipelineState = [ZYMetalContext.shared.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    NSAssert(error == nil, @"Error while creating render pass pipeline state %@", error);

    id<MTLCommandBuffer> commandBuffer = [ZYMetalContext.shared.commandQueue commandBuffer];
    
    {
        MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        renderPassDescriptor.colorAttachments[0].texture = inputTexture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [commandEncoder setRenderPipelineState:renderPipelineState];

        id<MTLBuffer> positionBuffer = [ZYMetalContext.shared.device newBufferWithBytes:normalVertices length:sizeof(normalVertices) options:MTLResourceStorageModeShared];
        id<MTLBuffer> texCoordinateBuffer = [ZYMetalContext.shared.device newBufferWithBytes:normalCoordinates length:sizeof(normalCoordinates) options:MTLResourceStorageModeShared];
        
        [commandEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBuffer:texCoordinateBuffer offset:0 atIndex:1];
        [commandEncoder setFragmentTexture:inputTexture atIndex:0];
        [commandEncoder setFragmentTexture:outputFramebuffer.texture atIndex:1];

        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        
        [commandEncoder endEncoding];
    }
    
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    for(id<ZYMetalInput> target in targets) {
        [target setInputFramebuffer:outputFramebuffer atIndex:0];
        [target newFrameReadyAtTime:frameTime atIndex:0];
    }
}

@end
