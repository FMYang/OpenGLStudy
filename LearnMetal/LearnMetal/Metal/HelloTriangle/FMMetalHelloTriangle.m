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
        // 1.创建一个GPU对象MTLCreateSystemDefaultDevice
        _device = MTLCreateSystemDefaultDevice();
        self.device = _device;
        
        // 2.创建一个MTLCommandQueue对象，然后用它创建一个MTLCommandBuffer对象
        _commandQueue = [_device newCommandQueue];
        
        NSError *errors;
        id <MTLLibrary> library = [_device newDefaultLibrary];
        id <MTLFunction> vertFunc = [library newFunctionWithName:@"hello_vertex"];
        id <MTLFunction> fragFunc = [library newFunctionWithName:@"hello_frament"];
        
        // 6.创建一个 MTLRenderPipelineDescriptor 对象，并且为它设置顶点着色程序和片段着色程序：
        MTLRenderPipelineDescriptor *renderpipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
        renderpipelineDesc.vertexFunction = vertFunc;
        renderpipelineDesc.fragmentFunction = fragFunc;
        renderpipelineDesc.colorAttachments[0].pixelFormat = self.currentDrawable.texture.pixelFormat;

        // 7.以 MTLRenderPipelineDescriptor 对象为参数，调用 newRenderPipelineStateWithDescriptor:error: 方法创建一个 MTLRenderPipelineState 对象。然后调用 MTLRenderCommandEncoder 的 setRenderPipelineState: 方法使 encoder 得到这个管线 state，以便绘制时候使用。
        _pipeline = [_device newRenderPipelineStateWithDescriptor:renderpipelineDesc error:&errors];

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

    // 3、创建一个 MTLRenderPassDescriptor 对象，它代表一系列的 attachment，attachment 将作为 command buffer 中被编码的渲染指令的最终产出目标。
    
    // 在这个例子中，只有第一个颜色 attachment 被设置和使用(假定变量 currentTexture 包含一个用于颜色 attachment 的 MTLTexture 对象) 。然后 MTLRenderPassDescriptor 被用来创建一个新的 MTLRenderCommandEncoder 对象。
    MTLRenderPassDescriptor *renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDesc.colorAttachments[0].texture = self.currentDrawable.texture;
    renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);

    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];

    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

    [renderEncoder setRenderPipelineState:_pipeline];

    // 4、创建两个MTLBuffer，然后调用 newBufferWithBytes:length:options: 方法来拷贝顶点坐标 posData 和顶点颜色数据 colData 到缓存存储空间中。
    id <MTLBuffer> posBuf = [_device newBufferWithBytes:posData length:sizeof(posData) options:MTLResourceStorageModeShared];
    id <MTLBuffer> colBuf = [_device newBufferWithBytes:colData length:sizeof(colData) options:MTLResourceStorageModeShared];

    [renderEncoder setTriangleFillMode:MTLTriangleFillModeFill];

    // 5、两次调用 MTLRenderCommandEncoder 对象的 setVertexBuffer:offset:atIndex: 方法来设置坐标和颜色。
    [renderEncoder setVertexBuffer:posBuf offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:colBuf offset:0 atIndex:1];
    
    // 8.调用 MTLRenderCommandEncoder 对象的 drawPrimitives:vertexStart:vertexCount: 方法，把绘制一个填充的三角形 (类型是 MTLPrimitiveTypeTriangle)的指令推入 command buffer中。
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    
    // 9.调用 endEncoding 方法来结束这个渲染 pass 的编码。最后调用 MTLCommandBuffer 的 commit 方法开始在设备上执行渲染指令。
    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];
}

@end
