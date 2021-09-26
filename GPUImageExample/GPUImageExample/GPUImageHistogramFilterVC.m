//
//  GPUImageHistogramFilterVC.m
//  GPUImageExample
//
//  Created by yfm on 2021/9/26.
//

#import "GPUImageHistogramFilterVC.h"
#import <GPUImage/GPUImage.h>

@interface GPUImageHistogramFilterVC ()
@property (nonatomic, strong) GPUImageVideoCamera *camera;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@end

@implementation GPUImageHistogramFilterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _gpuImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_gpuImageView];

    _camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    // 直方图
//    GPUImageHistogramFilter *filter = [[GPUImageHistogramFilter alloc] initWithHistogramType:kGPUImageHistogramRGB];
//    [_camera addTarget:filter];
//
//    GPUImageHistogramGenerator *histogramGraph = [[GPUImageHistogramGenerator alloc] init];
//    [histogramGraph forceProcessingAtSize:CGSizeMake(256.0, 256.0)];
//    [filter addTarget:histogramGraph];
//
//    [histogramGraph addTarget:_gpuImageView];
    
    
    // 单色
    GPUImageMonochromeFilter *filter = [[GPUImageMonochromeFilter alloc] init];
    [filter setColorRed:0.0 green:0.0 blue:1.0];
    
    [_camera addTarget:filter];
    [filter addTarget:_gpuImageView];
    
    [self.camera startCameraCapture];
}

@end
