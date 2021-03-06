//
//  FMCameraVC.m
//  FMMultiCamera
//
//  Created by yfm on 2021/9/27.
//

#import "FMCameraVC.h"
#import <AVFoundation/AVFoundation.h>
//#import "FMCameraOpenGLRGBView.h"
#import "FMFrameBuffer.h"
#import "FMCameraContext.h"
#import "FMDiplayView.h"
#import "ZYProCameraMovieRecorder.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

// 通用着色器
NSString *const ttVertexShaderString = SHADER_STRING(
   precision mediump float;
   attribute vec2 position;
   attribute vec2 textureCoord;

   varying vec2 aTextureCoord;
   varying vec2 aPosition;
                                                         
   void main()
   {
      gl_Position = vec4(position, 0.0, 1.0);
   
      aTextureCoord = textureCoord;
      aPosition = position;
   }
);

// 上下平分
NSString *const ttFragmentShaderString = SHADER_STRING(
    precision mediump float;
    varying vec2 aTextureCoord;
    varying vec2 aPosition;
    
    uniform sampler2D textureIndex1;
    uniform sampler2D textureIndex2;

    void main()
    {
        if(aPosition.y >= 0.0) {
            gl_FragColor = texture2D(textureIndex2, aTextureCoord);
        } else {
            gl_FragColor = texture2D(textureIndex1, aTextureCoord);
        }
    }
);

// 画中画
NSString *const picFragmentShaderString = SHADER_STRING(
    precision mediump float;
    varying vec2 aTextureCoord;
    varying vec2 aPosition;
    
    uniform sampler2D textureIndex1;
    uniform sampler2D textureIndex2;

    void main()
    {
        if((aPosition.y >= 0.27 && aPosition.y <= 0.9) && (aPosition.x >= 0.27 && aPosition.x <= 0.9)) {
            gl_FragColor = texture2D(textureIndex2, aTextureCoord);
        } else {
            gl_FragColor = texture2D(textureIndex1, aTextureCoord);
        }
    }
);

@interface FMCameraVC () <AVCaptureVideoDataOutputSampleBufferDelegate, ZYProCameraMovieRecorderDelegate> {
    dispatch_semaphore_t frameRenderingSemaphore;
    FMFrameBuffer *frameBuffer;
    
    GLuint _program;
    GLuint _vertexShader;
    GLuint _fragmentShader;
    
    GLuint _texture1;
    GLuint _texture2;
    
    FMDiplayView *ttDisplayView;
    
    //
    CVOpenGLESTextureRef _glTexture1;
    CVOpenGLESTextureRef _glTexture2;
}
@property (nonatomic) AVCaptureMultiCamSession *session;
@property (nonatomic) AVCaptureDeviceInput *backVideoInput;
@property (nonatomic) AVCaptureDeviceInput *frontVideoInput;
@property (nonatomic) AVCaptureConnection *backVideoConnection;
@property (nonatomic) AVCaptureConnection *frontVideoConnection;
@property (nonatomic) AVCaptureInputPort *backVideoPort;
@property (nonatomic) AVCaptureInputPort *frontVideoPort;
@property (nonatomic) dispatch_queue_t videoOutputQueue;
@property (nonatomic) dispatch_queue_t videoProcessQueue;
@property (nonatomic) dispatch_queue_t recordDelegateQueue;

@property (nonatomic) AVCaptureVideoDataOutput *backVideoOutput;
@property (nonatomic) AVCaptureVideoDataOutput *frontVideoOutput;

@property (nonatomic) UIButton *backBtn;
@property (nonatomic) UIButton *recordBtn;
@property (nonatomic) UIButton *typeSwitchBtn;

@property (nonatomic) ZYProCameraMovieRecorder *movieRecorder;
@property (nonatomic) CMTime videoRunningTime;
@property (nonatomic) CFTimeInterval baseTime;

@property (nonatomic) BOOL recording;
@property (nonatomic, strong) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;

@property (nonatomic) FMDisplayType displayType;

@end

@implementation FMCameraVC

- (void)dealloc {
    if(_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    if(_texture1) {
        glDeleteTextures(1, &_texture1);
        _texture1 = 0;
    }
    if(_texture2) {
        glDeleteTextures(1, &_texture2);
        _texture2 = 0;
    }
    frameBuffer = nil;
}

- (instancetype)init {
    if(self = [super init]) {
        _displayType = FMDisplayType_upAndDownSplit; // 默认上下分割
        frameRenderingSemaphore = dispatch_semaphore_create(1);
        _videoProcessQueue = dispatch_queue_create("com.yfm.videoProcessQueue", DISPATCH_QUEUE_SERIAL);
        _recordDelegateQueue = dispatch_queue_create("com.yfm.recordDelegateQueue", DISPATCH_QUEUE_SERIAL);
        [self configSession];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ttDisplayView = [[FMDiplayView alloc] initWithFrame:self.view.bounds type:self.displayType];
    [self.view addSubview:ttDisplayView];
    
    _backBtn = [[UIButton alloc] init];
    _backBtn.frame = CGRectMake(10, 34, 60, 44);
    [_backBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [_backBtn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    [_backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backBtn];
    
    _recordBtn = [[UIButton alloc] init];
    _recordBtn.frame = CGRectMake(90, 34, 60, 44);
    [_recordBtn setTitle:@"录像" forState:UIControlStateNormal];
    [_recordBtn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    [_recordBtn addTarget:self action:@selector(recordAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_recordBtn];
    
    _typeSwitchBtn = [[UIButton alloc] init];
    _typeSwitchBtn.frame = CGRectMake(170, 34, 80, 44);
    [_typeSwitchBtn setTitle:@"布局切换" forState:UIControlStateNormal];
    [_typeSwitchBtn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
    [_typeSwitchBtn addTarget:self action:@selector(displayTypeSwitchAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_typeSwitchBtn];
    
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

    // 后置摄像头 AVCaptureDeviceTypeBuiltInDualCamera AVCaptureDeviceTypeBuiltInWideAngleCamera
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
    
    // 设置分辨率帧率
    // back
    int frameRate = 30;
    AVCaptureDeviceFormat *backBestFormat = nil;
    for(AVCaptureDeviceFormat *format in backVideoDevice.formats) {
        CMFormatDescriptionRef formatDescriptionRef = format.formatDescription;
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescriptionRef);
        AVFrameRateRange *range = format.videoSupportedFrameRateRanges.firstObject;
        if(1920 == dimensions.width &&
           1080 == dimensions.height &&
           frameRate >= range.minFrameRate &&
           frameRate <= range.maxFrameRate) {
            backBestFormat = format;
            break;
        }
    }
    
    [backVideoDevice lockForConfiguration:nil];
    backVideoDevice.activeFormat = backBestFormat;
    [backVideoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, frameRate)];
    [backVideoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, frameRate)];
    [backVideoDevice unlockForConfiguration];
    
    // front
    AVCaptureDeviceFormat *frontBestFormat = nil;
    for(AVCaptureDeviceFormat *format in frontVideoDevice.formats) {
        CMFormatDescriptionRef formatDescriptionRef = format.formatDescription;
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(formatDescriptionRef);
        AVFrameRateRange *range = format.videoSupportedFrameRateRanges.firstObject;
        if(1920 == dimensions.width &&
           1080 == dimensions.height &&
           frameRate >= range.minFrameRate &&
           frameRate <= range.maxFrameRate) {
            frontBestFormat = format;
            break;
        }
    }
    [frontVideoDevice lockForConfiguration:nil];
    frontVideoDevice.activeFormat = frontBestFormat;
    [frontVideoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, frameRate)];
    [frontVideoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, frameRate)];
    [frontVideoDevice unlockForConfiguration];
    
    AVCaptureInputPort *backPort = [self.backVideoInput ports].firstObject;
    self.backVideoPort = backPort;
    
    AVCaptureInputPort *frontPort = [self.frontVideoInput ports].firstObject;
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
    
    [self createProgram];
        
    [_session commitConfiguration];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if(!CMTIME_IS_VALID(self.videoRunningTime)) {
        self.videoRunningTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        self.baseTime = CACurrentMediaTime();
    }
    
    if(dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
        return;
    }
    CFRetain(sampleBuffer);
    if(connection == self.backVideoConnection) {
        dispatch_async(self.videoProcessQueue, ^{
            [self processSampleBuffer:sampleBuffer index:1];
            CFRelease(sampleBuffer);
            
            dispatch_semaphore_signal(self->frameRenderingSemaphore);
        });
    } else if(connection == self.frontVideoConnection) {
        dispatch_async(self.videoProcessQueue, ^{
            [self processSampleBuffer:sampleBuffer index:2];
            CFRelease(sampleBuffer);
            
            dispatch_semaphore_signal(self->frameRenderingSemaphore);
        });
    }
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer index:(int)index {
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(cameraFrame);
    [self renderToTexture:CGSizeMake(bytesPerRow / 4, bufferHeight) pixelBuffer:cameraFrame index:index];
}

- (void)renderToTexture:(CGSize)bufferSize pixelBuffer:(CVPixelBufferRef)cameraFrame index:(int)index {
    [FMCameraContext useImageProcessingContext];

    if(!frameBuffer) {
        // 创建离屏帧缓存
//        frameBuffer = [[FMFrameBuffer alloc] initWithSize:CGSizeMake(bufferSize.width, bufferSize.height)];
        frameBuffer = [[FMFrameBuffer alloc] initWithSize:CGSizeMake(bufferSize.height, bufferSize.width)];
    }
    [frameBuffer activateFramebuffer];
    
    if(!_program) {
        [self createProgram];
    }
    glUseProgram(_program);

    // 上面矩形
    float vertices1[] = {
        -0.5, 1.0,
        0.5, 1.0,
        -0.5, 0.0,
        0.5, 0.0
    };
    
    // 下面矩形
    float vertices2[] = {
        -0.5, 0.0,
        0.5, 0.0,
        -0.5, -1.0,
        0.5, -1.0
    };
    
    // 全屏矩形
    float vertices4[] = {
        1.0, 1.0,
        -1.0, 1.0,
        1.0, -1.0,
        -1.0, -1.0
    };

    
    // 画中画矩形
    float vertices3[] = {
        0.9, 0.9,
        0.27, 0.9,
        0.9, 0.27,
        0.27, 0.27
    };
    
    // 旋转
    float textureCoord[] = {
        1.0, 1.0,
        1.0, 0.0,
        0.0, 1.0,
        0.0, 0.0,
    };
    
    // 镜像
    float textureCoord1[] = {
        1.0, 0.0,
        1.0, 1.0,
        0.0, 0.0,
        0.0, 1.0,
    };

//    [self generateTexture:cameraFrame index:index];
    [self generateTexture2:cameraFrame index:index];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE1);
//    glBindTexture(GL_TEXTURE_2D, _texture1);
    glUniform1i(glGetUniformLocation(_program, "textureIndex1"), 1);

    glActiveTexture(GL_TEXTURE2);
//    glBindTexture(GL_TEXTURE_2D, _texture2);
    glUniform1i(glGetUniformLocation(_program, "textureIndex2"), 2);

    GLuint textureCoordLoc = glGetAttribLocation(_program, "textureCoord");
    glEnableVertexAttribArray(textureCoordLoc);
        
    GLuint positionLoc = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(positionLoc);
    
    if(self.displayType == FMDisplayType_upAndDownSplit) {
        glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertices1);
        glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, textureCoord1);
    } else {
        glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertices4);
        glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, textureCoord1);
    }

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    if(self.displayType == FMDisplayType_upAndDownSplit) {
        glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertices2);
        glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, textureCoord);
    } else {
        glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertices3);
        glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, textureCoord);
    }

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    if(!self.outputVideoFormatDescription) {
        CMFormatDescriptionRef outputFormatDescription = NULL;
        CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, frameBuffer.pixelBuffer, &outputFormatDescription);
        // 使用合成的帧生成视频帧描述信息
        self.outputVideoFormatDescription = outputFormatDescription;
    }

    [ttDisplayView setInputFrameBuffer:frameBuffer];

    @synchronized (self) {
        if(self.movieRecorder.recordStatus == ZYProCameraRecordingStatusRecording) {
            if(frameBuffer.pixelBuffer != NULL) {
                [self.movieRecorder appendVideoPixelBuffer:frameBuffer.pixelBuffer withPresentationTime:[self frameTime]];
            }
        };
    };
}

- (CMTime)frameTime {
    CFTimeInterval interval = CACurrentMediaTime() - self.baseTime;
    CMTime intervalTime = CMTimeMake(interval * 600, 600);
    return CMTimeAdd(self.videoRunningTime, intervalTime);
}

- (void)generateTexture:(CVPixelBufferRef)pixelBuffer index:(int)index {
    int bufferHeight = (int) CVPixelBufferGetHeight(pixelBuffer);
    if(index == 1) {
        if(!_texture1) {
            glGenTextures(1, &_texture1);
        }
        glBindTexture(GL_TEXTURE_2D, _texture1);
    } else {
        if(!_texture2) {
            glGenTextures(1, &_texture2);
        }
        glBindTexture(GL_TEXTURE_2D, _texture2);
    }
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    // 复制图片像素的颜色数据到绑定的纹理缓存中。
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

//
- (void)generateTexture2:(CVPixelBufferRef)pixelBuffer index:(int)index {
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);

    if(index == 1) {
        glActiveTexture(GL_TEXTURE1);
        CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [FMCameraContext.shared coreVideoTextureCache], pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (GLsizei)width, (GLsizei)height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &_glTexture1);
        glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_glTexture1));
        glUniform1i(glGetUniformLocation(_program, "textureIndex1"), 1);
        CFRelease(_glTexture1);
    } else {
        glActiveTexture(GL_TEXTURE2);
        CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [FMCameraContext.shared coreVideoTextureCache], pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, (GLsizei)width, (GLsizei)height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &_glTexture2);
        glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_glTexture2));
        glUniform1i(glGetUniformLocation(_program, "textureIndex2"), 2);
        CFRelease(_glTexture2);
    }
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

- (void)createProgram {
    [FMCameraContext useImageProcessingContext]; // 一定要

    _vertexShader = glCreateShader(GL_VERTEX_SHADER);
    const char *vertexSource = (GLchar *)[ttVertexShaderString UTF8String];
    glShaderSource(_vertexShader, 1, &vertexSource, NULL);
    glCompileShader(_vertexShader);

    GLint logLength = 0;
    glGetShaderiv(_vertexShader, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(_vertexShader, logLength, &logLength, log);
        NSLog(@"vertexShader compile log:\n%s", log);
        free(log);
    }

    _fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    const char *fragmentSource;
    if(self.displayType == FMDisplayType_upAndDownSplit) {
        fragmentSource = (GLchar *)[ttFragmentShaderString UTF8String];
    } else {
        fragmentSource = (GLchar *)[picFragmentShaderString UTF8String];
    }
    glShaderSource(_fragmentShader, 1, &fragmentSource, NULL);
    glCompileShader(_fragmentShader);

    GLint alogLength = 0;
    glGetShaderiv(_fragmentShader, GL_INFO_LOG_LENGTH, &alogLength);
    if(logLength > 0) {
        GLchar *log = (GLchar *)malloc(alogLength);
        glGetShaderInfoLog(_fragmentShader, alogLength, &alogLength, log);
        NSLog(@"fragmentShader compile log:\n%s", log);
        free(log);
    }

    _program = glCreateProgram();
    glAttachShader(_program, _vertexShader);
    glAttachShader(_program, _fragmentShader);
    glLinkProgram(_program);

    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);

    glDeleteShader(_vertexShader);
    glDeleteShader(_fragmentShader);
}

#pragma mark -
- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordAction {
    if(self.recording) {
        [self.movieRecorder finishRecording];
    } else {
//        NSDictionary *recommendedSettings = [[self.backVideoOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie] mutableCopy];
//        NSDictionary *commentedCompressionProperties = [recommendedSettings objectForKey:AVVideoCompressionPropertiesKey];
//        // 设置帧率
//        [commentedCompressionProperties setValue:@(30) forKey:AVVideoExpectedSourceFrameRateKey];
//        [commentedCompressionProperties setValue:@(30) forKey:AVVideoMaxKeyFrameIntervalKey];
//        [recommendedSettings setValue:commentedCompressionProperties forKey:AVVideoCompressionPropertiesKey];
//        [recommendedSettings setValue:@(1080) forKey:AVVideoWidthKey];
//        [recommendedSettings setValue:@(1920) forKey:AVVideoHeightKey];

        NSURL *recordUrl = [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[NSTemporaryDirectory(), @"Movie.MOV"]]];
        _movieRecorder = [[ZYProCameraMovieRecorder alloc] initWithUrl:recordUrl delegate:self callBackQueue:self.recordDelegateQueue];
        [_movieRecorder addVideoTrackWithSourceFormatDescription:self.outputVideoFormatDescription transform:CGAffineTransformIdentity settings:nil];
        [_movieRecorder prepareToRecord];
    }
}

- (void)displayTypeSwitchAction {
    if(self.displayType == FMDisplayType_upAndDownSplit) {
        self.displayType = FMDisplayType_picInPic;
    } else {
        self.displayType = FMDisplayType_upAndDownSplit;
    }
    
    if(_program) {
        [FMCameraContext useImageProcessingContext];
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)setRecording:(BOOL)recording {
    _recording = recording;
    
    if(_recording) {
        [self.recordBtn setTitle:@"停止" forState:UIControlStateNormal];
        self.typeSwitchBtn.enabled = NO;
    } else {
        [self.recordBtn setTitle:@"录像" forState:UIControlStateNormal];
        self.typeSwitchBtn.enabled = YES;
    }
}

#pragma mark -
- (void)movieRecorderDidStartRecording:(ZYProCameraMovieRecorder *)recorder {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recording = YES;
    });
}

- (void)movieRecorder:(ZYProCameraMovieRecorder *)recorder didFailWithError:(NSError *)error {
    NSLog(@"error %@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recording = NO;
    });
}

- (void)movieRecorderWillStopRecording:(ZYProCameraMovieRecorder *)recorder {
    
}

- (void)movieRecorderDidStopRecording:(ZYProCameraMovieRecorder *)recorder url:(NSURL *)url {
    NSLog(@"%@", url);
    
    [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
        if(error) {
            NSLog(@"error %@", error);
        } else {
            NSLog(@"保存成功");
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.recording = NO;
    });
}

@end
