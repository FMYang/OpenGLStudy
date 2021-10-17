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
#import "FMCameraVC.h"

@interface ViewController () {
    FMMetalTriangleView *triangleView;
    FMMetalTextureView *textureView;
    FMCameraVC *_cameraVC;
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
    _cameraVC = [[FMCameraVC alloc] init];
    _cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:_cameraVC animated:YES completion:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    triangleView.frame = self.view.bounds;
    textureView.frame = self.view.bounds;
}

@end
