//
//  GPUImageVideoCamera.h
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "GPUImageContext.h"
#import "GPUImageOutput.h"
#import "GPUImageColorConversion.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageVideoCamera : GPUImageOutput {
    AVCaptureDeviceInput *videoInput;
    AVCaptureVideoDataOutput *videoOutput;
    
    GPUImageRotationMode outputRotation, internalRotation;
    dispatch_semaphore_t frameRenderingSemaphore;

    BOOL captureAsYUV;
    GLuint luminanceTexture, chrominanceTexture;
}

@property(readonly, nonatomic) BOOL isRunning;
@property(readonly, retain, nonatomic) AVCaptureSession *captureSession;
@property (readwrite, nonatomic, copy) NSString *captureSessionPreset;
@property (readwrite) int32_t frameRate;
@property(readonly) AVCaptureDevice *inputCamera;
@property(readwrite, nonatomic) UIInterfaceOrientation outputImageOrientation;

- (id)initWithSessionPreset:(NSString *)sessionPreset cameraPosition:(AVCaptureDevicePosition)cameraPosition;

- (void)startCameraCapture;
- (void)stopCameraCapture;

@end

NS_ASSUME_NONNULL_END
