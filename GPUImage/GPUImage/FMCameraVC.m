//
//  FMCameraVC.m
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import "FMCameraVC.h"
#import "GPUImageVideoCamera.h"
#import "GPUImageView.h"

@interface FMCameraVC() {
    GPUImageVideoCamera *videoCamera;
    GPUImageView *_glView;
}

@end

@implementation FMCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _glView = [[GPUImageView alloc] init];
    _glView.backgroundColor = UIColor.redColor;
    _glView.frame = self.view.bounds;
    [self.view addSubview:_glView];
    
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    [videoCamera addTarget:_glView];
    [videoCamera startCameraCapture];
}

@end