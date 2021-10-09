//
//  ViewController.m
//  FMOpenGL_Coord
//
//  Created by yfm on 2021/10/8.
//

#import "ViewController.h"
#import "FMCameraVC.h"

@interface ViewController () {
    FMCameraVC *cameraVC;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [[UIButton alloc] init];
    btn.frame = CGRectMake(100, 100, 100, 100);
    btn.backgroundColor = UIColor.redColor;
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClick {
    cameraVC = [[FMCameraVC alloc] init];
    cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:cameraVC animated:YES completion:nil];
}

@end
