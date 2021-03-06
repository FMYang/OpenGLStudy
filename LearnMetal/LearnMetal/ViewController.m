//
//  ViewController.m
//  LearnMetal
//
//  Created by yfm on 2021/10/12.
//

#import "ViewController.h"
#import "FMMetalTriangleView.h"
#import "FMMetalTextureView.h"
#import "FMMetalHelloTriangle.h"
#import "GPUCalculationVC.h"
#import "DrawViewContentVC.h"
#import "RenderTriangleVC.h"
#import "CustomRenderPassVC.h"
#import "CustomMetalViewVC.h"
#import "ProcessTextureWithComputeFuncVC.h"
#import "FilterChainVC.h"

@interface ViewController () {
    FMMetalTriangleView *triangleView;
    FMMetalTextureView *textureView;
    FilterChainVC *filterVC;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    FMMetalHelloTriangle *vv = [[FMMetalHelloTriangle alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:vv];
    
//    triangleView = [[FMMetalTriangleView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:triangleView];
    
//    textureView = [[FMMetalTextureView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:textureView];
    
    UIButton *btn = [[UIButton alloc] init];
    btn.frame = CGRectMake(100, 100, 100, 100);
    btn.backgroundColor = UIColor.redColor;
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClick {
    // 1.GPU上执行计算
//    GPUCalculationVC *vc = [[GPUCalculationVC alloc] init];
//    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];
    
    // 2.使用Metal绘制视图内容
//    DrawViewContentVC *vc = [[DrawViewContentVC alloc] init];
//    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];

    // 3、绘制三角形
//    RenderTriangleVC *vc = [[RenderTriangleVC alloc] init];
//    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];

    // 4、自定义渲染通道
//    CustomRenderPassVC *vc = [[CustomRenderPassVC alloc] init];
//    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];

    // 5、自定义MTKView
//    CustomMetalViewVC *vc = [[CustomMetalViewVC alloc] init];
//    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];
    
    // 6、使用计算函数处理纹理
//    ProcessTextureWithComputeFuncVC *vc = [[ProcessTextureWithComputeFuncVC alloc] init];
//    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];
    
    // 7、滤镜连
    filterVC = [[FilterChainVC alloc] init];
    filterVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:filterVC animated:YES completion:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    triangleView.frame = self.view.bounds;
    textureView.frame = self.view.bounds;
}

@end
