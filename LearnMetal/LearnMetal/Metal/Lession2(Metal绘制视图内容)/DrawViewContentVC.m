//
//  DrawViewContent.m
//  LearnMetal
//
//  Created by yfm on 2022/7/5.
//

/**
 Metal自动执行窗口系统任务、加载纹理和处理3D模型数据。
 */

#import "DrawViewContentVC.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface DrawViewContentVC () <MTKViewDelegate> {
    MTKView *_mtkView;
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
}
@end

@implementation DrawViewContentVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _device = MTLCreateSystemDefaultDevice();
    
    _commandQueue = [_device newCommandQueue];
    
    _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    /**
     enableSetNeedsDisplay默认为NO，以preferredFramesPerSecond的速率调用setNeedLayout，YES表示只有视图setNeedsDisplay时候调用。
     决定了drawInMTKView的调用次数。
     */
    _mtkView.enableSetNeedsDisplay = YES;
    _mtkView.device = _device;
    _mtkView.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0);
    _mtkView.delegate = self;
    [self.view addSubview:_mtkView];
}

#pragma mark -
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    NSLog(@"drawInMTKView");
    MTLRenderPassDescriptor *renderPassDescriptor = _mtkView.currentRenderPassDescriptor;
    if(renderPassDescriptor == nil) {
        return;
    }
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    [commandEncoder endEncoding];
    
    id<MTLDrawable> drawable = _mtkView.currentDrawable;
    
    [commandBuffer presentDrawable:drawable];

    [commandBuffer commit];
}

@end
