//
//  FMCameraVC.m
//  FMOpenGL_Coord
//
//  Created by yfm on 2021/10/8.
//

#import "FMCameraVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FMCameraOpenGLRGBView.h"

@interface FMCameraVC () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic) dispatch_queue_t outputQueue;
@property (nonatomic) FMCameraOpenGLRGBView *openglView;

@end

@implementation FMCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _openglView = [[FMCameraOpenGLRGBView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_openglView];
    
    [self configSession];
    [self.session startRunning];
}

- (void)configSession {
    _outputQueue = dispatch_queue_create("com.fm.session", DISPATCH_QUEUE_SERIAL);
    
    _session = [[AVCaptureSession alloc] init];
    
    [_session beginConfiguration];
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if([self.session canAddInput:_videoDeviceInput]) {
        [self.session addInput:_videoDeviceInput];
    }
    
    _dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    [_dataOutput setSampleBufferDelegate:self queue:_outputQueue];
    if([self.session canAddOutput:_dataOutput]) {
        [self.session addOutput:_dataOutput];
    }
    
    [_session commitConfiguration];
}

#pragma mark -
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.openglView renderPixelBuffer:cameraFrame];
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
