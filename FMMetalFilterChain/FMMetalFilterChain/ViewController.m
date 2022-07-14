//
//  ViewController.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/13.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "FMMetalCameraView.h"

// filter
#import "ZYCustomFilter.h"
#import "ZYMPSFilter.h"
#import "ZYMetalGrayFilter.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureInput *videoDeviceInput;
@property (nonatomic) dispatch_queue_t dataOutputQueue;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t renderQueue;
@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;

// MARK: - 滤镜

// 反色
@property (nonatomic) ZYMetalBaseFilter *reverseColorFilter;

// 灰度
@property (nonatomic) ZYMetalGrayFilter *grayFilter;

// 模糊
@property (nonatomic) ZYMetalBaseFilter *mpsFilter;

@property (nonatomic) FMMetalCameraView *metalView;

@end

@implementation ViewController

- (instancetype)init {
    if(self = [super init]) {
        _sessionQueue = dispatch_queue_create("fm.sessionQueue", DISPATCH_QUEUE_SERIAL);
        _dataOutputQueue = dispatch_queue_create("fm.dataOutputQueue", DISPATCH_QUEUE_SERIAL);
        _renderQueue = dispatch_queue_create("fm.renderQueue", DISPATCH_QUEUE_SERIAL);
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    
    _metalView = [[FMMetalCameraView alloc] init];
    _metalView.backgroundColor = UIColor.blackColor;
    CGFloat h = UIScreen.mainScreen.bounds.size.width * 16.0 / 9;
    _metalView.frame = CGRectMake(0, 0.5 * (UIScreen.mainScreen.bounds.size.height - h), UIScreen.mainScreen.bounds.size.width, h);
    [self.view addSubview:_metalView];
    
    self.session = [[AVCaptureSession alloc] init];

    dispatch_async(self.sessionQueue, ^{
        [self configSession];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.session startRunning];
}

- (void)configSession {
    self.videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    
    NSError *error = nil;
    AVCaptureInput *videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:&error];
    
    [self.session beginConfiguration];
    
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    if([self.session canAddInput:videoDeviceInput]) {
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
    } else {
        [self.session commitConfiguration];
        return;
    }
    
    if([self.session canAddOutput:self.videoDataOutput]) {
        [self.session addOutput:self.videoDataOutput];
        self.videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
    } else {
        [self.session commitConfiguration];
        return;
    }
    
    [self.session commitConfiguration];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFRetain(pixelBuffer);
    
    // 线程问题，MTKView在主线程渲染的
    dispatch_async(self.renderQueue, ^{
//    dispatch_async(dispatch_get_main_queue(), ^{
        CVMetalTextureRef texture = nil;
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, ZYMetalDevice.shared.textureCache, pixelBuffer, nil, MTLPixelFormatBGRA8Unorm, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 0, &texture);

        // 原图 -> 反色 -> 灰度
        id<MTLTexture> result1 = [self.reverseColorFilter render:CVMetalTextureGetTexture(texture)];
        id<MTLTexture> result2 = [self.grayFilter render:result1];
        [self.metalView renderPixelBuffer:result2];
        
        CFRelease(pixelBuffer);
        CFRelease(texture);
    });
}

- (ZYMetalBaseFilter *)reverseColorFilter {
    if(!_reverseColorFilter) {
        _reverseColorFilter = [[ZYMetalBaseFilter alloc] initWithMetalRenderCommand:[ZYCustomFilter new]];
    }
    return _reverseColorFilter;
}

- (ZYMetalBaseFilter *)mpsFilter {
    if(!_mpsFilter) {
        _mpsFilter = [[ZYMetalBaseFilter alloc] initWithMetalRenderCommand:[ZYMPSFilter new]];
    }
    return _mpsFilter;
}

- (ZYMetalGrayFilter *)grayFilter {
    if(!_grayFilter) {
        _grayFilter = [[ZYMetalGrayFilter alloc] initWithMetalRenderCommand:[ZYMetalGrayFilter new]];
    }
    return _grayFilter;
}

@end
