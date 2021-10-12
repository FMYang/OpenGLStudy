//
//  ViewController.m
//  FMOpenGL_textureCoord
//
//  Created by yfm on 2021/10/10.
//

#import "ViewController.h"
#import "FMCameraVC.h"

@interface ViewController ()
@property (nonatomic) FMCameraVC *cameraVC;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [[UIButton alloc] init];
    btn.backgroundColor = UIColor.redColor;
    btn.frame = CGRectMake(100, 100, 100, 100);
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClick {
    _cameraVC = [[FMCameraVC alloc] init];
    _cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:_cameraVC animated:YES completion:nil];
}

@end
