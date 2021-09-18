//
//  FMCameraVC.m
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import "FMCameraVC.h"
#import "GPUImageVideoCamera.h"
#import "GPUImageView.h"
#import "GPUImageSepiaFilter.h"

@interface FMCameraVC() {
    GPUImageVideoCamera *videoCamera;
    GPUImageView *_glView;
    GPUImageOutput<GPUImageInput> *filter;
}

@end

@implementation FMCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 要用initWithFrame初始化
    _glView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_glView];
    
    filter = [[GPUImageSepiaFilter alloc] init];

    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//    [videoCamera addTarget:filter];
//    [filter addTarget:_glView];
    
    [videoCamera addTarget:_glView];

    [videoCamera startCameraCapture];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
