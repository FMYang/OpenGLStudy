//
//  FMCameraVC.m
//  LearnMetal
//
//  Created by yfm on 2021/10/17.
//

#import "FMCameraVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FMMetalCameraView.h"

@interface FMCameraVC () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) FMMetalCameraView *previewView;
//@property (nonatomic)
//@property (nonatomic)

@end

@implementation FMCameraVC

- (void)configSession {
    _sessionQueue = dispatch_queue_create("com.fm.sessionQueue", DISPATCH_QUEUE_SERIAL);
    
    _session = [[AVCaptureSession alloc] init];
    
    [_session beginConfiguration];
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if([_session canAddInput:_videoInput]) {
        [_session addInput:_videoInput];
    }
    
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoDataOutput setSampleBufferDelegate:self queue:_sessionQueue];
    [_videoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCMPixelFormat_32BGRA)}];
    if([_session canAddOutput:_videoDataOutput]) {
        [_session addOutput:_videoDataOutput];
    }
    
    [_session commitConfiguration];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.previewView = [[FMMetalCameraView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.view addSubview:self.previewView];
    
    [self configSession];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.session startRunning];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.session stopRunning];
}

#pragma mark -
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef ref = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self processBuffer:ref];
}

- (void)processBuffer:(CVPixelBufferRef)pixelBuffer {
    float w = CVPixelBufferGetWidth(pixelBuffer);
    float h = CVPixelBufferGetHeight(pixelBuffer);
    NSLog(@"%@, %f, %f", pixelBuffer, w, h);
    
    [self.previewView renderPixelBuffer:pixelBuffer];
}

@end
