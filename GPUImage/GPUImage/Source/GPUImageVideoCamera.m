//
//  GPUImageVideoCamera.m
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import "GPUImageVideoCamera.h"
#import "GPUImageFilter.h"

@interface GPUImageVideoCamera() <AVCaptureVideoDataOutputSampleBufferDelegate> {
    NSDate *startingCaptureTime;
    dispatch_queue_t cameraProcessingQueue;
    
    GLProgram *yuvConversionProgram;
    GLint yuvConversionPositionAttribute, yuvConversionTextureCoordinateAttribute;
    GLint yuvConversionLuminanceTextureUniform, yuvConversionChrominanceTextureUniform;
    GLint yuvConversionMatrixUniform;
    
    const GLfloat *_preferredConversion;
    
    int imageBufferWidth, imageBufferHeight;
}

@end

@implementation GPUImageVideoCamera

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition {
    if(self = [super init]) {
        cameraProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
        
        frameRenderingSemaphore = dispatch_semaphore_create(1);

        _frameRate = 0;
        captureAsYUV = YES;
        internalRotation = kGPUImageNoRotation;
        
        _inputCamera = nil;
        
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for(AVCaptureDevice *device in devices) {
            if(device.position == cameraPosition) {
                _inputCamera = device;
            }
        }
        
        if(!_inputCamera) {
            return nil;
        }
        
        _captureSession = [[AVCaptureSession alloc] init];
        
        [_captureSession beginConfiguration];

        // 添加摄像头
        NSError *error = nil;
        videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_inputCamera error:&error];
        if([_captureSession canAddInput:videoInput]) {
            [_captureSession addInput:videoInput];
        } else {
            NSLog(@"Fail to add video input");
        }
        
        videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        videoOutput.alwaysDiscardsLateVideoFrames = NO;
        // 使用yuv格式图像
        [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        
        runSynchronouslyOnVideoProcessingQueue(^{
            if(captureAsYUV) {
                [GPUImageContext useImageProcessingContext];
                
                yuvConversionProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImageYUVFullRangeConversionForLAFragmentShaderString];
                
                if(!yuvConversionProgram.initialized) {
                    [yuvConversionProgram addAttribute:@"position"];
                    [yuvConversionProgram addAttribute:@"inputTextureCoordinate"];
                    
                    if(![yuvConversionProgram link]) {
                        NSString *progLog = [yuvConversionProgram programLog];
                        NSLog(@"Program link log: %@", progLog);
                        NSString *fragLog = [yuvConversionProgram fragmentShaderLog];
                        NSLog(@"Fragment shader compile log: %@", fragLog);
                        NSString *vertLog = [yuvConversionProgram vertexShaderLog];
                        NSLog(@"Vertex shader compile log: %@", vertLog);
                        yuvConversionProgram = nil;
                        NSAssert(NO, @"Filter shader link failed");
                    }
                }
                
                yuvConversionPositionAttribute = [yuvConversionProgram attributeIndex:@"position"];
                yuvConversionTextureCoordinateAttribute = [yuvConversionProgram attributeIndex:@"inputTextureCoordinate"];
                yuvConversionLuminanceTextureUniform = [yuvConversionProgram uniformIndex:@"luminanceTexture"];
                yuvConversionChrominanceTextureUniform = [yuvConversionProgram uniformIndex:@"chrominanceTexture"];
                yuvConversionMatrixUniform = [yuvConversionProgram uniformIndex:@"colorConversionMatrix"];
                
                [GPUImageContext setActiveShaderProgram:yuvConversionProgram];
            }
        });
        
        [videoOutput setSampleBufferDelegate:self queue:cameraProcessingQueue];
        if([_captureSession canAddOutput:videoOutput]) {
            [_captureSession addOutput:videoOutput];
        }
        
        _captureSessionPreset = sessionPreset;
        [_captureSession setSessionPreset:_captureSessionPreset];
        
        [_captureSession commitConfiguration];
    }
    return self;
}

#pragma mark - Manage the camera video stream
- (BOOL)isRunning {
    return _captureSession.isRunning;
}

- (void)startCameraCapture {
    if(!_captureSession.isRunning) {
        startingCaptureTime = NSDate.date;
        [_captureSession startRunning];
    }
}

- (void)stopCameraCapture {
    if(_captureSession.isRunning) {
        [_captureSession stopRunning];
    }
}

#define INITIALFRAMESTOIGNOREFORBENCHMARK 5
- (void)updateTargetsForVideoCameraUsingCacheTextureAtWidth:(int)bufferWidth height:(int)bufferHeight time:(CMTime)currentTime {
    for(id<GPUImageInput> currentTarget in targets) {
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        
        [currentTarget setInputRotation:outputRotation atIndex:textureIndexOfTarget];
        [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:textureIndexOfTarget];
        
        [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
    }
    
    [outputFramebuffer unlock];
    outputFramebuffer = nil;
    
    // filter start
    for(id<GPUImageInput> currentTarget in targets) {
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        [currentTarget newFrameReadyAtTime:currentTime atIndex:textureIndexOfTarget];
    }
    // filter end
}

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int)CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int)CVPixelBufferGetHeight(cameraFrame);
    CFTypeRef colorAttachments = CVBufferGetAttachment(cameraFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    if(colorAttachments != NULL) {
        if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
            _preferredConversion = kColorConversion601FullRange;
        }
    } else {
        _preferredConversion = kColorConversion601FullRange;
    }
    
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    [GPUImageContext useImageProcessingContext];
    
    CVOpenGLESTextureRef luminanceTextureRef = NULL;
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;

    // YUV格式
    if(CVPixelBufferGetPlaneCount(cameraFrame) > 0) {
        CVPixelBufferLockBaseAddress(cameraFrame, 0);
        
        if(imageBufferWidth != bufferWidth && imageBufferHeight != bufferHeight) {
            imageBufferWidth = bufferWidth;
            imageBufferHeight = bufferHeight;
        }
        
        glActiveTexture(GL_TEXTURE4);
        // 创建亮度纹理 Y-plane
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
        if(err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, luminanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // 创建色度纹理 UV-plane
        glActiveTexture(GL_TEXTURE5);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);

        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }

        chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        [self convertYUVToRGBOutput];
        
        int rotatedImageBufferWidth = bufferWidth, rotatedImageBufferHeight = bufferHeight;
        
        if (GPUImageRotationSwapsWidthAndHeight(internalRotation))
        {
            rotatedImageBufferWidth = bufferHeight;
            rotatedImageBufferHeight = bufferWidth;
        }
        
        [self updateTargetsForVideoCameraUsingCacheTextureAtWidth:rotatedImageBufferWidth height:rotatedImageBufferHeight time:currentTime];
        
        CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
        CFRelease(luminanceTextureRef);
        CFRelease(chrominanceTextureRef);
    }
}

// YUV转RGB
- (void)convertYUVToRGBOutput {
    [GPUImageContext setActiveShaderProgram:yuvConversionProgram];
    
    int rotatedImageBufferWidth = imageBufferWidth, rotatedImageBufferHeight = imageBufferHeight;

    if (GPUImageRotationSwapsWidthAndHeight(internalRotation)) {
        rotatedImageBufferWidth = imageBufferHeight;
        rotatedImageBufferHeight = imageBufferWidth;
    }

    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:CGSizeMake(rotatedImageBufferWidth, rotatedImageBufferHeight) textureOptions:self.outputTextureOptions];
    [outputFramebuffer activateFramebuffer];

    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, luminanceTexture);
    glUniform1i(yuvConversionLuminanceTextureUniform, 4);

    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
    glUniform1i(yuvConversionChrominanceTextureUniform, 5);

    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);

    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [GPUImageFilter textureCoordinatesForRotation:internalRotation]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if(!_captureSession.isRunning) return;
    
    if(output == videoOutput) {
        if(dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
            return;
        }
        
        CFRetain(sampleBuffer);
        runAsynchronouslyOnVideoProcessingQueue(^{
            // 处理每一帧
            [self processVideoSampleBuffer:sampleBuffer];
            
            CFRelease(sampleBuffer);
            dispatch_semaphore_signal(frameRenderingSemaphore);
        });
    }
}

#pragma mark - 方向
- (void)setOutputImageOrientation:(UIInterfaceOrientation)newValue {
    _outputImageOrientation = newValue;
    [self updateOrientationSendToTargets];
}

- (void)updateOrientationSendToTargets {
    runSynchronouslyOnVideoProcessingQueue(^{
        outputRotation = kGPUImageNoRotation;
        internalRotation = kGPUImageRotateRight;
        
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            [currentTarget setInputRotation:outputRotation atIndex:[[targetTextureIndices objectAtIndex:indexOfObject] integerValue]];
        }
    });
}


@end
