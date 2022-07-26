//
//  ZYMetalContext.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//

#import "ZYMetalContext.h"

/// 通过指定着色器，将输入纹理的数据渲染到目标纹理上
/// @param pipelineState 渲染管线（顶点着色器，片元着色器）
/// @param destinationTexture 渲染的目标纹理
/// @param sourceTexture 输入源纹理
id<MTLCommandBuffer> render(id<MTLRenderPipelineState> pipelineState,
                            id<MTLTexture> destinationTexture,
                            id<MTLTexture> sourceTexture,
                            float *vertices,
                            float *textureCoordinate) {
    id<MTLCommandBuffer> commandBuffer = [ZYMetalContext.shared.commandQueue commandBuffer];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
    renderPassDescriptor.colorAttachments[0].texture = destinationTexture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setRenderPipelineState:pipelineState];

    id<MTLBuffer> positionBuffer = [ZYMetalContext.shared.device newBufferWithBytes:vertices length:8 * sizeof(float) options:MTLResourceStorageModeShared];
    id<MTLBuffer> texCoordinateBuffer = [ZYMetalContext.shared.device newBufferWithBytes:textureCoordinate length:8 * sizeof(float) options:MTLResourceStorageModeShared];
    
    [commandEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:texCoordinateBuffer offset:0 atIndex:1];
    [commandEncoder setFragmentTexture:sourceTexture atIndex:0];

    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
    [commandEncoder endEncoding];
    
    return commandBuffer;
}

@implementation ZYMetalContext
@synthesize textureCache = _textureCache;
@synthesize commandQueue = _commandQueue;
@synthesize device = _device;
@synthesize library = _library;
@synthesize sharedFrameBufferCache = _sharedFrameBufferCache;
@synthesize normalRenderPipelineState = _normalRenderPipelineState;

+ (ZYMetalContext *)shared {
    static ZYMetalContext *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if(self = [super init]) {
        _device = MTLCreateSystemDefaultDevice();
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, _device, nil, &_textureCache);
        _commandQueue = [_device newCommandQueue];
        _library = [_device newDefaultLibrary];
    }
    return self;
}

#pragma mark -

- (ZYMetalFrameBufferCache *)sharedFrameBufferCache {
    if(!_sharedFrameBufferCache) {
        _sharedFrameBufferCache = [[ZYMetalFrameBufferCache alloc] init];
    }
    return _sharedFrameBufferCache;
}

- (id<MTLRenderPipelineState>)normalRenderPipelineState {
    if(!_normalRenderPipelineState) {
        MTLRenderPipelineDescriptor *cameraRenderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        cameraRenderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        cameraRenderPipelineDescriptor.vertexFunction = [self.library newFunctionWithName:@"normalVertex"];
        cameraRenderPipelineDescriptor.fragmentFunction = [self.library newFunctionWithName:@"normalFragmentShader"];

        NSError *error = nil;
        _normalRenderPipelineState = [self.device newRenderPipelineStateWithDescriptor:cameraRenderPipelineDescriptor error:&error];
        NSAssert(error == nil, @"Create normal render pipeline state failed %@", error);
    }
    return _normalRenderPipelineState;
}

@end
