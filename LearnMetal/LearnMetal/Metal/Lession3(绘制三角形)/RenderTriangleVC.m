//
//  RenderTriangleVC.m
//  LearnMetal
//
//  Created by yfm on 2022/7/5.
//

#import "RenderTriangleVC.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface RenderTriangleVC () <MTKViewDelegate> {
    MTKView *_mtkView;
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLBuffer> _positionBuffer;
    CGFloat w, h;
}
@end

@implementation RenderTriangleVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _device = MTLCreateSystemDefaultDevice();
        
    _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    /**
     enableSetNeedsDisplay默认为NO，以preferredFramesPerSecond的速率调用setNeedLayout，
     YES表示只有视图调用setNeedsDisplay时候调用，决定了drawInMTKView的调用频率。
     */
    _mtkView.enableSetNeedsDisplay = YES;
    _mtkView.device = _device;
    _mtkView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    _mtkView.delegate = self;
    [self.view addSubview:_mtkView];
    
    _commandQueue = [_device newCommandQueue];
    
    NSError *error;
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"triangleVertextShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"triangleFragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Simple Pipeline";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
    
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
    
    float vertices[] = {
         0.0,  0.5,
        -0.5, -0.5,
         0.5, -0.5,
    };
    
    _positionBuffer = [_device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceStorageModeShared];
}

#pragma mark -
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    MTLRenderPassDescriptor *renderPassDescriptor = _mtkView.currentRenderPassDescriptor;
    if(renderPassDescriptor) {
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        
//        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _mtkView.drawableSize.width, _mtkView.drawableSize.height, 0.0, 1.0}];
        
        [renderEncoder setRenderPipelineState:_pipelineState];
        
        // 注意区分设置顶点的方法setVertexBuffer、setVertexBytes
        [renderEncoder setVertexBuffer:_positionBuffer offset:0 atIndex:0];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:_mtkView.currentDrawable];
    }
    
    [commandBuffer commit];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
