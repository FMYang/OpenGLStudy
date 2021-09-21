//
//  FMFilterChainTestVC.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/20.
//

#import "FMFilterChainTestVC.h"
#import <AVFoundation/AVFoundation.h>
#import "FMCameraContext.h"
#import "FMFrameBuffer.h"
#import "FMDiplayView.h"

// 通用着色器
NSString *const testVertexShaderString = SHADER_STRING(
 precision lowp float;
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const testFragmentShaderString = SHADER_STRING(
 precision lowp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);



@interface FMFilterChainTestVC () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    dispatch_semaphore_t frameRenderingSemaphore;
    FMFrameBuffer *outputFramebuffer1;
    FMFrameBuffer *outputFramebuffer2;
    
    GLuint _program;
    GLuint _vertexShader;
    GLuint _fragmentShader;
    
    FMDiplayView *displayView;
}
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic) dispatch_queue_t cameraOutputQueue;
@property (nonatomic) dispatch_queue_t videoProcessQueue;

@end

@implementation FMFilterChainTestVC

- (void)dealloc {
    [self.videoOutput setSampleBufferDelegate:nil queue:nil];
}

- (instancetype)init {
    if(self = [super init]) {
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
        [_videoOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}]; // 32RGBA不支持，
        [_videoOutput setSampleBufferDelegate:self queue:_cameraOutputQueue];
        
        if([_captureSession canAddOutput:_videoOutput]) {
            [_captureSession addOutput:_videoOutput];
        }
        
        [self createProgram]; // 要在session startRunning前创建，否则失败
        
        [_captureSession commitConfiguration];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    displayView = [[FMDiplayView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:displayView];
    
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
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [FMCameraContext useImageProcessingContext];
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(cameraFrame);

    if(!outputFramebuffer1) {
        outputFramebuffer1 = [[FMFrameBuffer alloc] initWithSize:CGSizeMake(bytesPerRow / 4, bufferHeight) onlyTexture:YES];
    }
    
    [outputFramebuffer1 activateFramebuffer];
    glBindTexture(GL_TEXTURE_2D, [outputFramebuffer1 texture]);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));

    glBindTexture(GL_TEXTURE_2D, 0);
    
    //
    [self renderToTexture:CGSizeMake(bytesPerRow / 4, bufferHeight)];

    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
}

- (void)renderToTexture:(CGSize)bufferSize {
    /// =================== 离屏渲染 ====================
    [FMCameraContext useImageProcessingContext];

    if(!outputFramebuffer2) {
        outputFramebuffer2 = [[FMFrameBuffer alloc] initWithSize:CGSizeMake(bufferSize.width, bufferSize.height) onlyTexture:NO];
    }
    [outputFramebuffer2 activateFramebuffer];
    
    if(_program) {
        [self createProgram];
    }
    glUseProgram(_program);
        
    GLfloat vertex[] = {
        -1.0, -1.0,
        1.0, -1.0,
        -1.0, 1.0,
        1.0, 1.0
    };

    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };

    glClearColor(1.0, 1.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, outputFramebuffer1.texture);

    GLuint positionLoc = glGetAttribLocation(_program, "position");
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertex);
    glEnableVertexAttribArray(positionLoc);

    GLuint textureCoordLoc = glGetAttribLocation(_program, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureCoordLoc);
    glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, rotateRightTextureCoordinates);

    glUniform1i(glGetUniformLocation(_program, "inputImageTexture"), 2);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [displayView setInputFrameBuffer:outputFramebuffer2];
}

- (void)createProgram {
    [FMCameraContext useImageProcessingContext];

    _vertexShader = glCreateShader(GL_VERTEX_SHADER);
    const char *vertexSource = (GLchar *)[testVertexShaderString UTF8String];
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
    const char *fragmentSource = (GLchar *)[testFragmentShaderString UTF8String];
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
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
