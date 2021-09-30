//
//  ViewController.m
//  FMMultiCamera
//
//  Created by yfm on 2021/9/27.
//

#import "ViewController.h"
#import "FMCameraVC.h"

@interface ViewController ()
@property (nonatomic) FMCameraVC *camera;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *btn = [[UIButton alloc] init];
    btn.backgroundColor = UIColor.redColor;
    btn.frame = CGRectMake(100, 100, 100, 100);
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnClick {
    _camera = [[FMCameraVC alloc] init];
    _camera.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:_camera animated:YES completion:^{
        self->_camera = nil;
    }];
}

@end
