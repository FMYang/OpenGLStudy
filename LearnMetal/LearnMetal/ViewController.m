//
//  ViewController.m
//  LearnMetal
//
//  Created by yfm on 2021/10/12.
//

#import "ViewController.h"
#import "FMMetalTriangleView.h"
#import "FMMetalTextureView.h"

@interface ViewController () {
    FMMetalTriangleView *triangleView;
    FMMetalTextureView *textureView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    triangleView = [[FMMetalTriangleView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:triangleView];
    
    textureView = [[FMMetalTextureView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:textureView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    triangleView.frame = self.view.bounds;
    textureView.frame = self.view.bounds;
}

@end
