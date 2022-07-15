//
//  ZYProCameraMovieRecorder.h
//  proCamera
//
//  Created by yfm on 2021/6/25.
//

#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, ZYProCameraRecordingStatus) {
    ZYProCameraRecordingStatusIdle,
    ZYProCameraRecordingStatusPrepare,
    ZYProCameraRecordingStatusRecording,
    ZYProCameraRecordingStatusWillStop,
    ZYProCameraRecordingStatusDidStop,
    ZYProCameraRecordingStatusFailed,
};

NS_ASSUME_NONNULL_BEGIN

@protocol ZYProCameraMovieRecorderDelegate;

@interface ZYProCameraMovieRecorder : NSObject

@property (atomic, assign, readonly) ZYProCameraRecordingStatus recordStatus;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, readonly) CMTime startWriteTime;
@property (nonatomic, readonly) CMTime movieDuration;
@property (nonatomic, readonly) CMTime timelapseRecordDuration;
@property (atomic, assign) NSUInteger uid;
@property (atomic, assign) NSInteger curFrameRate;
@property (nonatomic, strong, readonly) dispatch_queue_t writtingQueue;

/// 初始化
/// @param url url
/// @param delegate 代理，delegate应该是弱引用
/// @param callBackQueue 代理回调队列
- (instancetype)initWithUrl:(NSURL *)url
                   delegate:(id<ZYProCameraMovieRecorderDelegate>)delegate
              callBackQueue:(dispatch_queue_t)callBackQueue;

- (void)addVideoTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription
                                       transform:(CGAffineTransform)transform
                                        settings:(NSDictionary * _Nullable)videoSettings;

/// 准备录制
///
/// 初始化AVAssetWriter，添加视频和音频AVAssetWriterInput并设置好音视频输出参数。
/// 此方法异步执行，可能会花费几百毫秒。配置视频和音频输出格式
- (void)prepareToRecord;

/// 添加视频帧
/// @param sampleBuffer 视频帧CMSampleBufferRef对象
- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/// 添加视频帧
/// @param pixelBuffer 视频帧CVPixelBufferRef对象
/// @param presentationTime 视频帧显示时间
- (void)appendVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer
          withPresentationTime:(CMTime)presentationTime;

/// 添加音频帧
/// @param sampleBuffer 音频帧
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/// 完成录制
- (void)finishRecording;

@end

@protocol ZYProCameraMovieRecorderDelegate <NSObject>
@required
/// 准备完成
- (void)movieRecorderDidStartRecording:(ZYProCameraMovieRecorder *)recorder;
/// 录制失败
- (void)movieRecorder:(ZYProCameraMovieRecorder *)recorder didFailWithError:(NSError *)error;
/// 录制将要停止
- (void)movieRecorderWillStopRecording:(ZYProCameraMovieRecorder *)recorder;
/// 录制停止
- (void)movieRecorderDidStopRecording:(ZYProCameraMovieRecorder *)recorder url:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
