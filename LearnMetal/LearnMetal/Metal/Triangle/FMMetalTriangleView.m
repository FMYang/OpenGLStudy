//
//  FMMetalTriangleView.m
//  LearnMetal
//
//  Created by yfm on 2021/10/13.
//

#import "FMMetalTriangleView.h"
#import "FMTriangleShaderTypes.h"

@interface FMMetalTriangleView() <MTKViewDelegate> {
    id<MTLDevice> _device;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLCommandQueue> _commandQueue;
    vector_uint2 _viewportSize;
}

@end

@implementation FMMetalTriangleView

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        NSError *error;
        
        // 1、创建metal设备对象
        _device = MTLCreateSystemDefaultDevice();
        self.device = _device;
        
        // 2、
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        
        // 顶点着色器
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        // 片元着色器
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"simaple pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
        
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
    static const AAPLVertex triangleVertices[] =
    {
        // 2D positions,    RGBA colors
        { {  0.5,  -0.5 }, { 1, 0, 0, 1 } },
        { { -0.5,  -0.5 }, { 0, 1, 0, 1 } },
        { {    0,   0.5 }, { 0, 0, 1, 1 } },
    };

    // Create a new command buffer for each render pass to the current drawable.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // Obtain a renderPassDescriptor generated from the view's drawable textures.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil) {
        // Create a render command encoder.
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set the region of the drawable to draw into.
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, 0.0, 1.0 }];
        
        [renderEncoder setRenderPipelineState:_pipelineState];

        // Pass in the parameter data.
        [renderEncoder setVertexBytes:triangleVertices
                               length:sizeof(triangleVertices)
                              atIndex:AAPLVertexInputIndexVertices];

        // Draw the triangle.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:3];

        [renderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable.
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // Finalize rendering here & push the command buffer to the GPU.
    [commandBuffer commit];
}


@end
