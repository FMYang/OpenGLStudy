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
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) FMMetalCameraView *previewView;

@end

@implementation FMCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    
    self.previewView = [[FMMetalCameraView alloc] init];
    CGFloat h = UIScreen.mainScreen.bounds.size.width * 16.0 / 9;
    self.previewView.frame = CGRectMake(0, 0.5 * (UIScreen.mainScreen.bounds.size.height - h), UIScreen.mainScreen.bounds.size.width, h);
    [self.view addSubview:self.previewView];
    
    // 测试x420图标变灰
//    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 44, 44)];
//    [btn setImage:[UIImage imageNamed:@"ZYCamera_switch"] forState:UIControlStateNormal];
//    [self.view addSubview:btn];
    
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

- (void)configSession {
    _sessionQueue = dispatch_queue_create("com.fm.sessionQueue", DISPATCH_QUEUE_SERIAL);
    
    _session = [[AVCaptureSession alloc] init];
    
    [_session beginConfiguration];
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.videoDevice = videoDevice;
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
    
    if([self bestFormat:videoDevice]) {
        [videoDevice lockForConfiguration:nil];
        videoDevice.activeFormat = [self bestFormat:videoDevice];
        videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 30);
        videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 30);
        [videoDevice unlockForConfiguration];
    }
    
    [_session commitConfiguration];
}

- (AVCaptureDeviceFormat *)bestFormat:(AVCaptureDevice *)device {
    for(AVCaptureDeviceFormat *format in device.formats) {
        CMFormatDescriptionRef descriptionRef = format.formatDescription;
        int mediaSubType = CMFormatDescriptionGetMediaSubType(descriptionRef);
        if(mediaSubType == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange) {
            return format;
        }
    }
    return nil;
}

#pragma mark -
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef ref = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.previewView renderPixelBuffer:ref];
}

@end
