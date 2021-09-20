//
//  FMCameraFilterVC.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/18.
//

#import "FMCameraFilterVC.h"
#import "FMCameraOpenGLView.h"
#import "FMCameraOpenGLRGBView.h"
#import "FMCameraLutView.h"

@interface FMCameraFilterVC() <AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_semaphore_t frameRenderingSemaphore;
    
    BOOL _captureAsYUV;
}
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic) dispatch_queue_t cameraOutputQueue;
@property (nonatomic) dispatch_queue_t videoProcessQueue;
@property (nonatomic) FMCameraOpenGLView *glView;
@property (nonatomic) FMCameraOpenGLRGBView *rgbGlView;
@property (nonatomic) FMCameraLutView *lutView;

@end

@implementation FMCameraFilterVC

- (void)dealloc {
    [self.videoOutput setSampleBufferDelegate:nil queue:nil];
}

- (instancetype)init {
    if(self = [super init]) {
        _captureAsYUV = NO;
        frameRenderingSemaphore = dispatch_semaphore_create(1);

        _cameraOutputQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        _videoProcessQueue = dispatch_queue_create("com.yfm.videoProcessQueue", DISPATCH_QUEUE_SERIAL);
        
        _captureSession = [[AVCaptureSession alloc] init];
        
        [_captureSession beginConfiguration];
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        if([_captureSession canAddInput:_videoInput]) {
            [_captureSession addInput:_videoInput];
        }
        
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoOutput.alwaysDiscardsLateVideoFrames = NO;
        if(_captureAsYUV) {
            [_videoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}]; // yuv 420f fullRange
        } else {
            [_videoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}]; // 32RGBA不支持，
        }
        [_videoOutput setSampleBufferDelegate:self queue:_cameraOutputQueue];
        
        if([_captureSession canAddOutput:_videoOutput]) {
            [_captureSession addOutput:_videoOutput];
        }
        
        [_captureSession commitConfiguration];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    if(_captureAsYUV) {
//        _glView = [[FMCameraOpenGLView alloc] initWithFrame:self.view.bounds];
//        [self.view addSubview:_glView];
//    } else {
//        _rgbGlView = [[FMCameraOpenGLRGBView alloc] initWithFrame:self.view.bounds];
//        [self.view addSubview:_rgbGlView];
//    }
    
    // 基于RGB的数据
    _lutView = [[FMCameraLutView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_lutView];
    
    [self startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopRunning];
}

- (void)startRunning {
    if(!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)stopRunning {
    if(self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
        return;
    }
    CFRetain(sampleBuffer);
    dispatch_async(self.videoProcessQueue, ^{
        [self processSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
        
        dispatch_semaphore_signal(self->frameRenderingSemaphore);
    });
}

#pragma mark - process sampleBuffer
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
//    if(_captureAsYUV) {
//        [self.glView renderPixelBuffer:videoFrame];
//    } else {
//        [self.rgbGlView renderPixelBuffer:videoFrame];
//    }
    
    [_lutView renderPixelBuffer:videoFrame];
}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
