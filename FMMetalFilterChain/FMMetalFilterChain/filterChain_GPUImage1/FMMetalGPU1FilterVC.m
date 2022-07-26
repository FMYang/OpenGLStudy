//
//  FMMetalGPU1FilterVC.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import "FMMetalGPU1FilterVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FMMetalView.h"

// filter
#import "ZYMetalGrayFilter1.h"
#import "ZYMetalReverseColorFilter.h"
#import "ZYMetalSignleColorFilter.h"
#import "ZYMetalOutputFilter.h"

// record
#import "ZYProCameraMovieRecorder.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface FMMetalGPU1FilterVC () <AVCaptureVideoDataOutputSampleBufferDelegate, ZYProCameraMovieRecorderDelegate>
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureInput *videoDeviceInput;
@property (nonatomic) dispatch_queue_t dataOutputQueue;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) dispatch_queue_t renderQueue;
@property (nonatomic) dispatch_queue_t recordCallbackQueue;
@property (nonatomic) AVCaptureConnection *dataOutputConnection;
@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_semaphore_t frameRenderingSemaphore;
// MARK: - 滤镜

// 灰度
@property (nonatomic) ZYMetalFilter *baseFilter;
@property (nonatomic) ZYMetalReverseColorFilter *reverseColorFilter;
@property (nonatomic) ZYMetalSignleColorFilter *singleColorFilter;
@property (nonatomic) ZYMetalGrayFilter1 *grayFilter;
@property (nonatomic) ZYMetalOutputFilter *outputFilter;

@property (nonatomic) FMMetalView *metalView;

// MARK: - 录像
@property (nonatomic) ZYProCameraMovieRecorder *movieRecorder;
@property (nonatomic) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic) BOOL isRecording;
@property (nonatomic) UIButton *recordButton;

@end

@implementation FMMetalGPU1FilterVC

- (instancetype)init {
    if(self = [super init]) {
        _sessionQueue = dispatch_queue_create("fm.sessionQueue", DISPATCH_QUEUE_SERIAL);
        _dataOutputQueue = dispatch_queue_create("fm.dataOutputQueue", DISPATCH_QUEUE_SERIAL);
        _renderQueue = dispatch_queue_create("fm.renderQueue", DISPATCH_QUEUE_SERIAL);
        _recordCallbackQueue = dispatch_queue_create("fm.recordCallbackQueue", DISPATCH_QUEUE_SERIAL);
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _frameRenderingSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    
    _metalView = [[FMMetalView alloc] init];
    _metalView.backgroundColor = UIColor.blackColor;
    CGFloat h = UIScreen.mainScreen.bounds.size.width * 16.0 / 9;
    _metalView.frame = CGRectMake(0, 0.5 * (UIScreen.mainScreen.bounds.size.height - h), UIScreen.mainScreen.bounds.size.width, h);
    [self.view addSubview:_metalView];
    
    _recordButton = [[UIButton alloc] init];
    _recordButton.backgroundColor = UIColor.whiteColor;
    _recordButton.frame = CGRectMake(0, 0, 60, 60);
    _recordButton.center = CGPointMake(UIScreen.mainScreen.bounds.size.width * 0.5, UIScreen.mainScreen.bounds.size.height - 100);
    _recordButton.layer.cornerRadius = 30;
    _recordButton.layer.masksToBounds = YES;
    [_recordButton addTarget:self action:@selector(recordAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_recordButton];
    
    // 滤镜链
    [self.baseFilter addTarget:self.reverseColorFilter]; // -> 反色
    [self.reverseColorFilter addTarget:self.singleColorFilter]; // 反色 -> 单色
    [self.singleColorFilter addTarget:self.outputFilter]; // 单色 -> 输出（录像）
    [self.singleColorFilter addTarget:self.grayFilter]; // 单色 -> 灰度
    [self.grayFilter addTarget:self.metalView]; // 灰度 -> 预览

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
        
        self.dataOutputConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    } else {
        [self.session commitConfiguration];
        return;
    }
    
    [self.session commitConfiguration];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(dispatch_semaphore_wait(self.frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
        return;
    }
    self.outputVideoFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFRetain(pixelBuffer);
    dispatch_async(self.renderQueue, ^{
        [self.baseFilter push:pixelBuffer frameTime:presentationTimeStamp];
        
        if(self.isRecording) {
            CFRetain(pixelBuffer);
            dispatch_async(self.movieRecorder.writtingQueue, ^{
                ZYMetalFrameBuffer *outputFrameBuffer = [self.outputFilter getFrameBuffer];
                CVPixelBufferRef pixel = outputFrameBuffer.pixelBuffer;
                [self.movieRecorder appendVideoPixelBuffer:pixel withPresentationTime:presentationTimeStamp];
                [outputFrameBuffer unlock];
                CFRelease(pixelBuffer);
            });
        }
        
        CFRelease(pixelBuffer);
        dispatch_semaphore_signal(self.frameRenderingSemaphore);
    });
}

// 滤镜链
- (ZYMetalFilter *)baseFilter {
    if(!_baseFilter) {
        _baseFilter = [[ZYMetalFilter alloc] initWithFragmentFunction:@"normalFragmentShader"];
    }
    return _baseFilter;
}

- (ZYMetalGrayFilter1 *)grayFilter {
    if(!_grayFilter) {
        _grayFilter = [[ZYMetalGrayFilter1 alloc] init];
    }
    return _grayFilter;
}

- (ZYMetalReverseColorFilter *)reverseColorFilter {
    if(!_reverseColorFilter) {
        _reverseColorFilter = [[ZYMetalReverseColorFilter alloc] init];
    }
    return _reverseColorFilter;
}

- (ZYMetalSignleColorFilter *)singleColorFilter {
    if(!_singleColorFilter) {
        _singleColorFilter = [[ZYMetalSignleColorFilter alloc] init];
    }
    return _singleColorFilter;
}

- (ZYMetalOutputFilter *)outputFilter {
    if(!_outputFilter) {
        _outputFilter = [[ZYMetalOutputFilter alloc] init];
    }
    return _outputFilter;
}

#pragma mark - record
- (void)recordAction {
    [self startRecord];
}

- (void)startRecord {
    if(!self.isRecording) {
        NSURL *recordUrl = [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[NSTemporaryDirectory(), @"Movie.MOV"]]];
        NSDictionary *videoSetting = [self.videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
        _movieRecorder = [[ZYProCameraMovieRecorder alloc] initWithUrl:recordUrl delegate:self callBackQueue:self.recordCallbackQueue];
        [_movieRecorder addVideoTrackWithSourceFormatDescription:self.outputVideoFormatDescription transform:[self transformFromVideoBufferOrientationToOrientation:AVCaptureVideoOrientationPortrait withAutoMirroring:NO] settings:videoSetting];
        [_movieRecorder prepareToRecord];
    } else {
        [self.movieRecorder finishRecording];
    }
}

- (void)movieRecorderDidStartRecording:(ZYProCameraMovieRecorder *)recorder {
    NSLog(@"movieRecorderDidStartRecording");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isRecording = YES;
    });
}

- (void)movieRecorder:(ZYProCameraMovieRecorder *)recorder didFailWithError:(NSError *)error {
    NSLog(@"movieRecorder didFailWithError");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isRecording = NO;
    });
}

- (void)movieRecorderWillStopRecording:(ZYProCameraMovieRecorder *)recorder {
    NSLog(@"movieRecorderWillStopRecording");
}

- (void)movieRecorderDidStopRecording:(ZYProCameraMovieRecorder *)recorder url:(NSURL *)url {
    NSLog(@"movieRecorderDidStopRecording");
    
    [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
        if(error) {
            NSLog(@"error %@", error);
        } else {
            NSLog(@"保存成功");
        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.isRecording = NO;
    });
}

- (void)setIsRecording:(BOOL)isRecording {
    _isRecording = isRecording;
    self.recordButton.backgroundColor = isRecording ? UIColor.redColor : UIColor.whiteColor;
}

#pragma mark - 方向
- (CGAffineTransform)transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)orientation withAutoMirroring:(BOOL)mirror {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CGFloat orientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation(orientation);
    CGFloat videoOrientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation(self.dataOutputConnection.videoOrientation);
    
    CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    transform = CGAffineTransformMakeRotation( angleOffset );
    
    if (self.videoDevice.position == AVCaptureDevicePositionFront ) {
        if ( mirror ) {
            if ( UIInterfaceOrientationIsPortrait( (UIInterfaceOrientation)orientation ) ) {
                transform = CGAffineTransformScale( transform, 1, -1 );
                
            }else{
                transform = CGAffineTransformScale( transform, -1, 1 );
                
            }
        } else {
            if ( UIInterfaceOrientationIsPortrait( (UIInterfaceOrientation)orientation ) ) {
                transform = CGAffineTransformRotate( transform, M_PI );
            }
        }
    }
    
    return transform;
}

static CGFloat angleOffsetFromPortraitOrientationToOrientation(AVCaptureVideoOrientation orientation) {
    CGFloat angle = 0.0;
    
    switch ( orientation ) {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    
    return angle;
}

@end
