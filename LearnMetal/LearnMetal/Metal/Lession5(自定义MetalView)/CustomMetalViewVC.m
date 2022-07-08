//
//  CustomMetalViewVC.m
//  LearnMetal
//
//  Created by yfm on 2022/7/7.
//

#import "CustomMetalViewVC.h"
#import "CustomMTKView.h"
#import <Metal/Metal.h>
#import "CustomRenderer.h"

@interface CustomMetalViewVC () <CustomMTKViewDelegate> {
    CustomMTKView *_mtkView;
    CustomRenderer *_render;
}
@end

@implementation CustomMetalViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    
    _mtkView = [[CustomMTKView alloc] initWithFrame:self.view.bounds];
    
    _mtkView.metalLayer.device = device;
    
    _mtkView.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    
    _mtkView.delegate = self;
    
    [self.view addSubview:_mtkView];
    
    _render = [[CustomRenderer alloc] initWithMetalDevice:device drawablePixelFormat:_mtkView.metalLayer.pixelFormat];
}

#pragma mark - CustomMTKViewDelegate
- (void)drawableResize:(CGSize)size {
    [_render drawableResize:size];
}

- (void)renderToMetalLayer:(CAMetalLayer *)metalLayer {
    [_render renderToMetalLayer:metalLayer];
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
