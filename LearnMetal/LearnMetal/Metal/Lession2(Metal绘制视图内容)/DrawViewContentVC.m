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
     enableSetNeedsDisplay默认为NO，以preferredFramesPerSecond的速率调用setNeedLayout，
     YES表示只有视图调用setNeedsDisplay时候调用，决定了drawInMTKView的调用频率。
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
    /**
     创建渲染通道描述符
     当绘制时，GPU将结果存储到纹理中，纹理是包含图像数据且可供GPU访问的内存块。MTKView创建了需要绘制到视图中的所有纹理。
     它创建多个纹理，以便在渲染到下一个纹理时显示上一个纹理的内容。
     要进行绘制，需要创建一个渲染通道，它是绘制到一组纹理中的一系列渲染命令。渲染过程中使用时，纹理也称为渲染目标。
     要创建渲染通道，需要一个渲染描述符。这个例子中，不是配置自己的渲染通道描述符，而是要求MetalKit视图为你创建一个。
     */
    MTLRenderPassDescriptor *renderPassDescriptor = _mtkView.currentRenderPassDescriptor;
    if(renderPassDescriptor == nil) {
        return;
    }
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // 创建渲染通道，使用MTLRenderCommandEncoder对象将其编码到命令缓冲区来创建渲染通道。
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    // 调用编码器的endEncoding方法，表示pass已经完成
    [commandEncoder endEncoding];
    
    // MTKView自动创建可绘制对象来管理其纹理，连接到Core Animation对象。
    id<MTLDrawable> drawable = _mtkView.currentDrawable;
    
    /**
     在屏幕上显示Drawable，纹理不会自动在屏幕上显示新内容。在Metal中，可以在屏幕上显示的纹理又MTLDrawable对象管理，
     要显示内容，需要呈现可绘制对象。
     */
    [commandBuffer presentDrawable:drawable];

    // 提交缓冲区命令，供GPU执行
    [commandBuffer commit];
}

@end
