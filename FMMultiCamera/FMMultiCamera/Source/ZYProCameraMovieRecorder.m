//
//  ZYProCameraMovieRecorder.m
//  proCamera
//
//  Created by yfm on 2021/6/25.
//
//  无阻塞的实时电影录像机

#import "ZYProCameraMovieRecorder.h"

static NSUInteger uniqueId = 1;

@interface ZYProCameraMovieRecorder()
@property (atomic, assign, readwrite) ZYProCameraRecordingStatus recordStatus;

@property (nonatomic, strong, readwrite) dispatch_queue_t writtingQueue;
@property (nonatomic, weak) id<ZYProCameraMovieRecorderDelegate> delegate;
@property (nonatomic, strong) dispatch_queue_t delegateCallBackQueue;

@property (nonatomic, strong) AVAssetWriter *assetWritter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) NSDictionary *videoTrackSettings;
@property (nonatomic, assign) CGAffineTransform videoTrackTransform;
@property (nonatomic, strong) __attribute__((NSObject)) CMFormatDescriptionRef videoTrackSourceFormatDescription;

@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) NSDictionary *audioTrackSettings;
@property (nonatomic, strong) __attribute__((NSObject)) CMFormatDescriptionRef audioTrackSourceFormatDescription;

@property (nonatomic, assign, readwrite) CMTime startWriteTime;

@end

@implementation ZYProCameraMovieRecorder

- (void)dealloc {
    if(_videoTrackSourceFormatDescription) {
        CFRelease(_videoTrackSourceFormatDescription);
    }
    if(_audioTrackSourceFormatDescription) {
        CFRelease(_audioTrackSourceFormatDescription);
    }
}

#pragma mark - API
- (instancetype)initWithUrl:(NSURL *)url
                   delegate:(id<ZYProCameraMovieRecorderDelegate>)delegate
              callBackQueue:(dispatch_queue_t)callBackQueue {
    NSParameterAssert(delegate != nil);
    NSParameterAssert(callBackQueue != nil);
    NSParameterAssert(url != nil);
    
    if(self = [super init]) {
        _startWriteTime = kCMTimeInvalid;
        _writtingQueue = dispatch_queue_create("com.zyproCamera.movieRecorder.write", DISPATCH_QUEUE_SERIAL);
        _url = url;
        _delegate = delegate;
        _delegateCallBackQueue = callBackQueue;
        _videoTrackTransform = CGAffineTransformIdentity;
        
        @synchronized (self) {
            _uid = uniqueId++;
        }
    }
    return self;
}

- (void)addVideoTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription
                                       transform:(CGAffineTransform)transform
                                        settings:(NSDictionary *)videoSettings {
    if(formatDescription == NULL) {
        NSLog(@"NULL format description");
        return;
    }
    
    @synchronized (self) {
        if(self.recordStatus != ZYProCameraRecordingStatusIdle) {
            NSLog(@"Cannot add tracks while not idle");
            return;
        }
        
        if(self.videoTrackSourceFormatDescription) {
            NSLog(@"Cannot add more than one video track");
            return;
        }
        
        self.videoTrackSourceFormatDescription = (CMFormatDescriptionRef)CFRetain(formatDescription);
        self.videoTrackTransform = transform;
        self.videoTrackSettings = [videoSettings copy];
    }
}

- (void)addAudioTrackWithSourceFromatDescription:(CMFormatDescriptionRef)formatDescription
                                        settings:(NSDictionary *)audioSettings {
    if(formatDescription == NULL) {
        NSLog(@"NULL format description");
        return;
    }
    
    @synchronized (self) {
        if(self.recordStatus != ZYProCameraRecordingStatusIdle) {
            NSLog(@"Cannot add tracks while not idle");
            return;
        }
        
        if(self.audioTrackSourceFormatDescription) {
            NSLog(@"Cannot add more than one audio track");
            return;
        }
        self.audioTrackSourceFormatDescription = (CMFormatDescriptionRef)CFRetain(formatDescription);
        self.audioTrackSettings = [audioSettings copy];
    }
}

// 准备录制
- (void)prepareToRecord {
    @synchronized (self) {
        if(self.recordStatus != ZYProCameraRecordingStatusIdle) {
            NSLog(@"Already prepared, cannot prepare again");
            return;
        }
        
        [self transitionToStatus:ZYProCameraRecordingStatusPrepare error:nil];
    }
    
    dispatch_async(self.writtingQueue, ^{
        @autoreleasepool {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:self.url error:NULL];
            
            self.assetWritter = [[AVAssetWriter alloc] initWithURL:self.url fileType:AVFileTypeQuickTimeMovie error:&error];
            
            // 设置视频输入
            if(!error && self.videoTrackSourceFormatDescription) {
                [self setupAssetWriterVideoInputWithSourceFormatDescription:self.videoTrackSourceFormatDescription
                                                                  transform:self.videoTrackTransform
                                                                   settings:self.videoTrackSettings
                                                                      error:&error];
                
                NSLog(@"videoSettings = %@", self.videoTrackSettings);
            }
            
            // 设置音频输入
            if(!error && self.audioTrackSourceFormatDescription) {
                [self setupAssetWriteAudioInputWithSourceFormatDescription:self.audioTrackSourceFormatDescription
                                                                  settings:self.audioTrackSettings
                                                                     error:&error];
                
                NSLog(@"audioSetting = %@", self.audioTrackSettings);
            }
            
            if(!error) {
                BOOL success = [self.assetWritter startWriting];
                if(!success) {
                    error = self.assetWritter.error;
                }
            }
            
            @synchronized (self) {
                if(error) {
                    NSLog(@"prepareToRecord = %@", error);
                    [self transitionToStatus:ZYProCameraRecordingStatusFailed error:error];
                } else {
                    [self transitionToStatus:ZYProCameraRecordingStatusRecording error:nil];
                }
            }
        }
    });
}

// 添加音频帧
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
}

// 添加视频帧
- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
}

// 添加视频帧
- (void)appendVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer
          withPresentationTime:(CMTime)presentationTime {
    NSLog(@"%f", CMTimeGetSeconds(presentationTime));
    CMSampleBufferRef sampleBuffer = NULL;
    
    CMSampleTimingInfo timingInfo = {0,};
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = presentationTime;
    
    CMFormatDescriptionRef outputFormatDescription = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &outputFormatDescription);
    
    // CVPixelBufferRef to CMSampleBufferRef
    OSStatus err = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                                      pixelBuffer,
                                                      true,
                                                      NULL,
                                                      NULL,
                                                      outputFormatDescription,
                                                      &timingInfo,
                                                      &sampleBuffer);
    if(sampleBuffer) {
        [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
        CFRelease(sampleBuffer);
    } else {
        NSLog(@"sample buffer create failed (%i)", (int)err);
    }
}

// 将sampleBuffer写入视频和音频轨道
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType {
    if ( sampleBuffer == NULL ) {
        NSLog(@"NULL sample buffer");
        return;
    }
    
    @synchronized (self) {
        if(self.recordStatus < ZYProCameraRecordingStatusRecording ) {
            NSLog(@"Not ready to record yet");
            return;
        }
    }
    
    CFRetain(sampleBuffer);
    dispatch_async(self.writtingQueue, ^{
        @autoreleasepool {
            @synchronized (self) {
                if(self.recordStatus > ZYProCameraRecordingStatusRecording) {
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            //start还没开始启动启动写人
            if (!CMTIME_IS_VALID(self.startWriteTime) ) {
                if (mediaType ==AVMediaTypeVideo) {
                    self.startWriteTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    [self.assetWritter startSessionAtSourceTime:self.startWriteTime];
                } else {
                    CFRelease(sampleBuffer);
                    return;
                }
            }
            
            AVAssetWriterInput *input = (mediaType == AVMediaTypeVideo) ? self.videoInput : self.audioInput;
            
            @synchronized (self) {
                if(input.readyForMoreMediaData) {
                    BOOL success = [input appendSampleBuffer:sampleBuffer];
                    if(!success) {
                        NSError *error = self.assetWritter.error;
                        NSLog(@"appendSampleBuffer error %@", error);
                        @synchronized (self) {
                            [self transitionToStatus:ZYProCameraRecordingStatusFailed error:error];
                        }
                    }
                } else {
                    NSLog( @"%@ input not ready for more media data, dropping buffer", mediaType );
                }
                CFRelease(sampleBuffer);
            }
        }
    });
}


// 完成录制
- (void)finishRecording {
    dispatch_async(self.writtingQueue, ^{
        @synchronized (self) {
            if(self.recordStatus != ZYProCameraRecordingStatusRecording) {
                NSLog(@"not ZYProCameraRecordingStatusRecording status, cannot stop");
                return;
            }
            
            [self transitionToStatus:ZYProCameraRecordingStatusWillStop error:nil];
        }
        
        // 标记该输入完成，不再处理输入的媒体样本，同时标记readyForMoreMediaData为NO
        if(self.assetWritter.status == AVAssetWriterStatusWriting) {
            [self.videoInput markAsFinished];
            [self.audioInput markAsFinished];
        }
        
        [self.assetWritter finishWritingWithCompletionHandler:^{
            @synchronized (self) {
                NSError *error = self.assetWritter.error;
                if(error) {
                    [self transitionToStatus:ZYProCameraRecordingStatusFailed error:error];
                } else {
                    [self transitionToStatus:ZYProCameraRecordingStatusDidStop error:nil];
                }
            }
            
            self.startWriteTime = kCMTimeInvalid;
        }];
    });
}

- (AVAssetWriterStatus)status {
    return self.assetWritter.status;
}

- (CMTime)movieDuration {
    if(CMTIME_IS_VALID(self.startWriteTime)) {
        CMTime curTime = CMTimeMake(CACurrentMediaTime() * 100000, 100000);
        CMTime duration = CMTimeSubtract(curTime, self.startWriteTime);
        return duration;
    }
    return kCMTimeZero;
}

#pragma mark - private
// 设置视频轨道input对象
- (BOOL)setupAssetWriterVideoInputWithSourceFormatDescription:(CMFormatDescriptionRef)videoFormatDescription
                                                    transform:(CGAffineTransform)transform
                                                     settings:(NSDictionary *)videoSettings
                                                        error:(NSError **)errorOut {
    if(!videoSettings) {
        videoSettings = [self defaultVideoSettings:videoFormatDescription];
    }
    
    if([self.assetWritter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]) {
        self.videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                         outputSettings:videoSettings
                                                       sourceFormatHint:videoFormatDescription];
        self.videoInput.expectsMediaDataInRealTime = YES;
//        self.videoInput.transform = transform;
                
        if([self.assetWritter canAddInput:self.videoInput]) {
            [self.assetWritter addInput:self.videoInput];
        } else {
            if(errorOut) {
                *errorOut = [[self class] cannotSetupInputError];
            }
            return NO;
        }
    } else {
        if(errorOut) {
            *errorOut = [[self class] cannotSetupInputError];
            return NO;
        }
    }
    
    return YES;
}

// 设置音频轨道input对象
- (BOOL)setupAssetWriteAudioInputWithSourceFormatDescription:(CMFormatDescriptionRef)audioFormatDescription
                                                    settings:(NSDictionary *)audioSettings
                                                       error:(NSError **)errorOut {
    if(!audioSettings) {
        audioSettings = [self defaultAudioSettings];
    }
    
    if([self.assetWritter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio]) {
        self.audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                         outputSettings:audioSettings
                                                       sourceFormatHint:audioFormatDescription];
        self.audioInput.expectsMediaDataInRealTime = YES;
        
        if([self.assetWritter canAddInput:self.audioInput]) {
            [self.assetWritter addInput:self.audioInput];
        } else {
            if(errorOut) {
                *errorOut = [[self class] cannotSetupInputError];
            }
            return NO;
        }
    } else {
        if(errorOut) {
            *errorOut = [[self class] cannotSetupInputError];
        }
        return NO;
    }
    
    return YES;
}

#pragma mark -
- (void)transitionToStatus:(ZYProCameraRecordingStatus)recordStatus error:(NSError *)error {
    NSLog(@"record status from %@ to %@", [self stringOfStatus:self.recordStatus], [self stringOfStatus:recordStatus]);
    if(self.recordStatus == recordStatus) return;
    self.recordStatus = recordStatus;
    
    dispatch_async(self.delegateCallBackQueue, ^{
        if(self.recordStatus == ZYProCameraRecordingStatusRecording) {
            [self.delegate movieRecorderDidStartRecording:self];
        } else if(self.recordStatus == ZYProCameraRecordingStatusFailed) {
            [self.delegate movieRecorder:self didFailWithError:error];
        } else if(self.recordStatus == ZYProCameraRecordingStatusWillStop) {
            [self.delegate movieRecorderWillStopRecording:self];
        } else if(self.recordStatus == ZYProCameraRecordingStatusDidStop) {
            [self.delegate movieRecorderDidStopRecording:self url:self.url];
        }
    });
}

- (NSString *)stringOfStatus:(ZYProCameraRecordingStatus)status {
    NSString *str = @"Idle";
    switch (status) {
        case ZYProCameraRecordingStatusIdle:
            str = @"Idle";
            break;
            
        case ZYProCameraRecordingStatusPrepare:
            str = @"Prepare";
            break;
            
        case ZYProCameraRecordingStatusRecording:
            str = @"Recording";
            break;
            
        case ZYProCameraRecordingStatusWillStop:
            str = @"WillStop";
            break;
            
        case ZYProCameraRecordingStatusDidStop:
            str = @"DidStop";
            break;
            
        case ZYProCameraRecordingStatusFailed:
            str = @"Failed";
            break;
            
        default:
            break;
    }
    return str;
}

#pragma mark - internal
// 默认视频编码格式
- (NSDictionary *)defaultVideoSettings:(CMFormatDescriptionRef)videoFormatDescriptionRef {
    NSDictionary *videoSettings = nil;
    float bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescriptionRef);
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond;
    
    if(numPixels < (650 * 480)) {
        bitsPerPixel = 4.05;
    } else {
        bitsPerPixel = 10.1;
    }
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *compressionProperties = @{
        AVVideoAverageBitRateKey: @(bitsPerSecond),
        AVVideoExpectedSourceFrameRateKey: @(30),
        AVVideoMaxKeyFrameIntervalKey: @(30)
    };
    
    videoSettings = @{
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: @(dimensions.width),
        AVVideoHeightKey: @(dimensions.height),
        AVVideoCompressionPropertiesKey: compressionProperties
    };

    return videoSettings;
}

// 默认音频编码格式
- (NSDictionary *)defaultAudioSettings {
    return @{AVEncoderBitRatePerChannelKey: @(96000), // 每个通道的比特率
             AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable, // 编码器使用的比特率策略，Variable表示变量值策略
             AVEncoderAudioQualityForVBRKey: @(AVAudioQualityHigh), // 动态比特率，只和AVAudioBitRateStrategy_Variable有关
             AVFormatIDKey: @(kAudioFormatMPEG4AAC), // 编码格式
             AVNumberOfChannelsKey: @(1), // 通道数
             AVSampleRateKey: @(44100)}; // 采样率
}

// 错误提示
+ (NSError *)cannotSetupInputError {
    NSString *localizedDescription = NSLocalizedString( @"Recording cannot be started", nil );
    NSString *localizedFailureReason = NSLocalizedString( @"Cannot setup asset writer input.", nil );
    NSDictionary *errorDict = @{ NSLocalizedDescriptionKey : localizedDescription,
                                 NSLocalizedFailureReasonErrorKey : localizedFailureReason };
    return [NSError errorWithDomain:@"com.zyproCamera.errorDomain" code:0 userInfo:errorDict];
}

- (void)teardownAssetWriterAndInputs {
    _assetWritter = nil;
    _videoInput = nil;
    _audioInput = nil;
}

@end
