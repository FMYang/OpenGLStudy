//
//  FMCameraVC.m
//  FMMultiCamera
//
//  Created by yfm on 2021/9/27.
//

#import "FMCameraVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FMCameraOpenGLRGBView.h"

@interface FMCameraVC () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) AVCaptureMultiCamSession *session;
@property (nonatomic) AVCaptureDeviceInput *backVideoInput;
@property (nonatomic) AVCaptureDeviceInput *frontVideoInput;
@property (nonatomic) AVCaptureConnection *backVideoConnection;
@property (nonatomic) AVCaptureConnection *frontVideoConnection;
@property (nonatomic) AVCaptureInputPort *backVideoPort;
@property (nonatomic) AVCaptureInputPort *frontVideoPort;
@property (nonatomic) dispatch_queue_t videoOutputQueue;

@property (nonatomic) AVCaptureVideoDataOutput *backVideoOutput;
@property (nonatomic) AVCaptureVideoDataOutput *frontVideoOutput;

@property (nonatomic) FMCameraOpenGLRGBView *displayView;
@end

@implementation FMCameraVC

- (instancetype)init {
    if(self = [super init]) {
        [self configSession];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _displayView = [[FMCameraOpenGLRGBView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_displayView];
    
    [self.session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.session stopRunning];
}

- (void)configSession {
    
    _videoOutputQueue = dispatch_queue_create("com.yfm.outputQueue", DISPATCH_QUEUE_SERIAL);
    
    _session = [[AVCaptureMultiCamSession alloc] init];
    
    [_session beginConfiguration];
    
    _backVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_backVideoOutput setSampleBufferDelegate:self queue:_videoOutputQueue];
    [_backVideoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
    
    _frontVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_frontVideoOutput setSampleBufferDelegate:self queue:_videoOutputQueue];
    [_frontVideoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];

    if([self.session canAddOutput:_backVideoOutput]) {
        [self.session addOutput:_backVideoOutput];
    }
    
    if([self.session canAddOutput:_frontVideoOutput]) {
        [self.session addOutput:_frontVideoOutput];
    }

    // 后置摄像头
    AVCaptureDevice *backVideoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    AVCaptureDeviceInput *backVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backVideoDevice error:nil];
    if([self.session canAddInput:backVideoDeviceInput]) {
        [self.session addInputWithNoConnections:backVideoDeviceInput];
        self.backVideoInput = backVideoDeviceInput;
    }
    
    // 前置摄像头
    AVCaptureDevice *frontVideoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    AVCaptureDeviceInput *frontVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontVideoDevice error:nil];
    if([self.session canAddInput:frontVideoDeviceInput]) {
        [self.session addInputWithNoConnections:frontVideoDeviceInput];
        self.frontVideoInput = frontVideoDeviceInput;
    }
    
    AVCaptureInputPort *backPort = [self.backVideoInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:backVideoDevice.deviceType sourceDevicePosition:AVCaptureDevicePositionBack].firstObject;
    self.backVideoPort = backPort;
    
    AVCaptureInputPort *frontPort = [self.frontVideoInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:frontVideoDevice.deviceType sourceDevicePosition:AVCaptureDevicePositionFront].firstObject;
    self.frontVideoPort = frontPort;
    
    AVCaptureConnection *backConnection = [AVCaptureConnection connectionWithInputPorts:@[self.backVideoPort] output:self.backVideoOutput];
    self.backVideoConnection = backConnection;
    
    AVCaptureConnection *frontConnection = [AVCaptureConnection connectionWithInputPorts:@[self.frontVideoPort] output:self.frontVideoOutput];
    self.frontVideoConnection = frontConnection;
    
    if([self.session canAddConnection:self.backVideoConnection]) {
        [self.session addConnection:self.backVideoConnection];
    }
    
    if([self.session canAddConnection:self.frontVideoConnection]) {
        [self.session addConnection:self.frontVideoConnection];
    }
        
    [_session commitConfiguration];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(output == self.backVideoOutput) {
        CVPixelBufferRef backPixelRef = CMSampleBufferGetImageBuffer(sampleBuffer);
        NSLog(@"back");
        [self.displayView renderPixelBuffer:backPixelRef];
    } else if(connection == self.frontVideoConnection) {
        CVPixelBufferRef frontPixelRef = CMSampleBufferGetImageBuffer(sampleBuffer);
        NSLog(@"front");
    }
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
