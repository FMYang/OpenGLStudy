//
//  CustomRenderPassVC.m
//  LearnMetal
//
//  Created by yfm on 2022/7/7.
//

/**
 渲染通道（MTLRenderPassDescriptor）是绘制到一组纹理中的一系列命令。
 */

#import "CustomRenderPassVC.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface CustomRenderPassVC () <MTKViewDelegate> {
    MTKView *_mtkView;
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    // 要渲染的纹理
    id<MTLTexture> _renderTargetTexture;
    // 纹理渲染通道描述
    MTLRenderPassDescriptor *_renderToTextureRenderPassDescriptor;
    // 渲染离屏纹理的管线
    id<MTLRenderPipelineState> _renderToTextureRenderPipeline;
    // 渲染屏幕的管线
    id<MTLRenderPipelineState> _drawableRenderPipeline;
    
    float _aspectRatio;
}
@end

@implementation CustomRenderPassVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _device = MTLCreateSystemDefaultDevice();
        
    _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    _mtkView.enableSetNeedsDisplay = YES;
    _mtkView.device = _device;
    _mtkView.clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
    _mtkView.delegate = self;
    [self.view addSubview:_mtkView];
    
    _commandQueue = [_device newCommandQueue];
    
    // 要创建纹理首先需要创建纹理描述
    MTLTextureDescriptor *texDescriptor = [[MTLTextureDescriptor alloc] init];
    texDescriptor.textureType = MTLTextureType2D;
    texDescriptor.width = 512;
    texDescriptor.height = 512;
    texDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    // 需要在离屏渲染通道将数据渲染到纹理，设置为MTLTextureUsageRenderTarget，在另一个通道读取纹理数据，设置为MTLTextureUsageShaderRead
    texDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    
    // 使用纹理描述对象创建离屏渲染的纹理
    _renderTargetTexture = [_device newTextureWithDescriptor:texDescriptor];
    
    /**
     设置离屏渲染通道的描述对象，必须为目标配置加载操作（loadAction）和存储操作（storeAction）
     
     Metal使用加载和存储操作来优化GPU管理纹理数据的方式，大型纹理会消耗大量内存，处理这些纹理会消耗大量内存
     带宽。正确设置渲染目标操作可以减少GPU用于访问纹理的内存带宽量，从而提高性能和电池寿命。
     */
    _renderToTextureRenderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
    _renderToTextureRenderPassDescriptor.colorAttachments[0].texture = _renderTargetTexture;
    // 加载操作擦除渲染目标的内容
    _renderToTextureRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    // 使用白色擦除纹理
    _renderToTextureRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
    // 存储操作将擦除的数据存储回纹理，因为下一阶段要用到
    _renderToTextureRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    NSError *error;
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        
    // 创建绘制到屏幕的渲染管线对象
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Drawable Render Pipeline";
    pipelineStateDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"customDrawableVertextShader"];
    pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"customDrawableFragmentShader"];
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
    pipelineStateDescriptor.vertexBuffers[0].mutability = MTLMutabilityImmutable;

    // 创建屏幕渲染管线
    _drawableRenderPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_drawableRenderPipeline, @"Failed to create pipeline state to render to screen: %@", error);
    
    // 创建绘制到屏幕外的渲染管线对象
    pipelineStateDescriptor.label = @"Offscreen Render Pipeline";
    pipelineStateDescriptor.sampleCount = 1;
    pipelineStateDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"customTextureVertextShader"];
    pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"customTextureFragmentShader"];
    // 指向屏幕外纹理
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _renderTargetTexture.pixelFormat;
    
    // 创建离屏纹理渲染管线
    _renderToTextureRenderPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_renderToTextureRenderPipeline, @"Failed to create pipeline state to render to texture: %@", error);
}

#pragma mark -
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    _aspectRatio =  (float)size.height / (float)size.width;
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Command Buffer";
    
    {
        /**
         离屏纹理渲染
         
         渲染通道进行编码前，了解Metal如何在GPU上调度命令非常重要。
         当应用程序将命令缓冲区提交到命令队列时，默认情况下，Metal必须按顺序执行命令。为了提高性能和更好地
         利用GPU。Metal可以同时运行命令，只要能保证顺序。为了实现这一点，当一个pass写入资源，并且随后的Pass
         读取它时，Metal会检测依赖关系并自动延迟后面的pass执行，直到第一个pass完成。因此，与需要显示同步CPU
         和GPU工作不同，该示例不需要做任何特别的事情，Metal确保它们按顺序执行。
         */
        float vertices[] = {
             0.0,  0.5,
            -0.5, -0.5,
             0.5, -0.5,
        };

        id<MTLBuffer> verticesBuffer = [_device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderToTextureRenderPassDescriptor];
        renderEncoder.label = @"Offscreen Render Pass";
        [renderEncoder setRenderPipelineState:_renderToTextureRenderPipeline];

        [renderEncoder setVertexBuffer:verticesBuffer offset:0 atIndex:0];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

        [renderEncoder endEncoding];
    }
    
    // 渲染到屏幕上
    MTLRenderPassDescriptor *drawableRenderPassDescriptor = _mtkView.currentRenderPassDescriptor;
    if(drawableRenderPassDescriptor) {
        // 顶点坐标
        float quadVertices[] = {
             0.5, -0.5,
            -0.5, -0.5,
            -0.5,  0.5,
             0.5, -0.5,
            -0.5,  0.5,
             0.5,  0.5
        };
        
        // 纹理坐标
        float texVertices[] = {
             1.0, 1.0,
             0.0, 1.0,
             0.0, 0.0,
             1.0, 1.0,
             0.0, 0.0,
             1.0, 0.0
        };
        
        id<MTLBuffer> quadVerticesBuffer = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
        id<MTLBuffer> texVerticesBuffer = [_device newBufferWithBytes:texVertices length:sizeof(texVertices) options:MTLResourceStorageModeShared];

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:drawableRenderPassDescriptor];
        
        renderEncoder.label = @"Drawable Render Pass";
                        
        [renderEncoder setRenderPipelineState:_drawableRenderPipeline];
        
        [renderEncoder setVertexBuffer:quadVerticesBuffer offset:0 atIndex:0];
        [renderEncoder setVertexBuffer:texVerticesBuffer offset:0 atIndex:1];
        [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:0];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:_mtkView.currentDrawable];
    }
    
    /**
     当样本提交命令缓冲区时，Metal 会依次执行两个渲染通道。在这种情况下，Metal 检测到第一个渲染通道写入屏幕外纹理，第二个通道从它读取。当 Metal 检测到这种依赖关系时，它会阻止随后的 pass 执行，直到 GPU 完成第一个 pass。
     */
    [commandBuffer commit];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
