//
//  FMMetalHelloTriangle.m
//  LearnMetal
//
//  Created by yfm on 2021/10/15.
//

#import "FMMetalHelloTriangle.h"
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>

@interface FMMetalHelloTriangle() <MTKViewDelegate> {
    id<MTLDevice> _device;
    vector_uint2 _viewportSize;
    id <MTLRenderPipelineState> _pipeline;
    id <MTLCommandQueue> _commandQueue;
}
@end

@implementation FMMetalHelloTriangle

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        _device = MTLCreateSystemDefaultDevice();
        self.device = _device;
        
        NSError *errors;
        id <MTLLibrary> library = [_device newDefaultLibrary];
        id <MTLFunction> vertFunc = [library newFunctionWithName:@"hello_vertex"];
        id <MTLFunction> fragFunc = [library newFunctionWithName:@"hello_frament"];

        MTLRenderPipelineDescriptor *renderpipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
        renderpipelineDesc.vertexFunction = vertFunc;
        renderpipelineDesc.fragmentFunction = fragFunc;
        renderpipelineDesc.colorAttachments[0].pixelFormat = self.currentDrawable.texture.pixelFormat;

        _pipeline = [_device newRenderPipelineStateWithDescriptor:renderpipelineDesc error:&errors];

        _commandQueue = [_device newCommandQueue];

        // 设置缓冲区初始大小
        [self mtkView:self drawableSizeWillChange:self.drawableSize];
        self.delegate = self;
    }
    return self;
}

#pragma mark - MTKViewDelegate

/**
 每当内容大小发生变化时调用。当视图的窗口调整大小或设备方向发生变化时，就会发生这种情况。
 这允许应用程序根据视图的大小调整渲染分辨率。
 */
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    // 保存可绘制的尺寸，以传递到顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

/**
 当需要更新视图的内容时调用。此方法中，可以创建一个命令缓冲区，告诉GPU要绘制什么和何时在屏幕上显示的命令进行编码，并排队由
 GPU执行该命令缓冲区。有时也称为绘制帧。可以将帧视为屏幕上的单个图像。在交互式应用程序中，如游戏，可能会每秒绘制许多帧。
 */
- (void)drawInMTKView:(nonnull MTKView *)view {
    static const float posData[] = {
        0.0, 0.33, 0.0, 1.0,
        -0.33, -0.33, 0.0, 1.0,
        0.33, -0.33, 0.0, 1.0,
    };
    
    static const float colData[] = {
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0,
    };

    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    MTLRenderPassDescriptor *renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDesc.colorAttachments[0].texture = self.currentDrawable.texture;
    renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);

    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];

    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

    [renderEncoder setRenderPipelineState:_pipeline];

    id <MTLBuffer> posBuf = [_device newBufferWithBytes:posData length:sizeof(posData) options:MTLResourceStorageModeShared];
    id <MTLBuffer> colBuf = [_device newBufferWithBytes:colData length:sizeof(colData) options:MTLResourceStorageModeShared];

    [renderEncoder setTriangleFillMode:MTLTriangleFillModeFill];

    [renderEncoder setVertexBuffer:posBuf offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:colBuf offset:0 atIndex:1];
    
    // 绘制三角形
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];
}

@end
