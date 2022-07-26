//
//  ViewController.m
//  GPUSimpleVideoFilter
//
//  Created by yfm on 2022/7/26.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#import <AssetsLibrary/ALAssetsLibrary.h>

@interface ViewController () {
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *sepiaFilter;
    GPUImageOutput<GPUImageInput> *falseColorFilter;
    GPUImageMovieWriter *movieWriter;

    UISlider *slider;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;

    sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    ((GPUImageSepiaFilter *)sepiaFilter).intensity = 0.5;
    
    falseColorFilter = [[GPUImageFalseColorFilter alloc] init];
    
    [videoCamera addTarget:falseColorFilter];
    GPUImageView *filterView = [[GPUImageView alloc] init];
    filterView.frame = self.view.bounds;
    [self.view addSubview:filterView];
    
    slider = [[UISlider alloc] init];
    slider.frame = CGRectMake(40, 100, 300, 30);
    slider.minimumValue = 0.0;
    slider.maximumValue = 1.0;
    slider.value = 0.5;
    [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:slider];
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
    movieWriter.encodingLiveVideo = YES;
    
    [falseColorFilter addTarget:sepiaFilter];
    [sepiaFilter addTarget:movieWriter];
    [sepiaFilter addTarget:filterView];
    
    [videoCamera startCameraCapture];
    
    double delayToStartRecording = 0.5;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, delayToStartRecording * NSEC_PER_SEC);
    dispatch_after(startTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"Start recording");
        
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];

        double delayInSeconds = 10.0;
        dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
            
            [sepiaFilter removeTarget:movieWriter];
            videoCamera.audioEncodingTarget = nil;
            [movieWriter finishRecording];
            NSLog(@"Movie completed");
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:movieURL])
            {
                [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
                 {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         if (error) {
                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                             [alert show];
                         } else {
                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                             [alert show];
                         }
                     });
                 }];
            }
            
//            [videoCamera.inputCamera lockForConfiguration:nil];
//            [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
//            [videoCamera.inputCamera unlockForConfiguration];
        });
    });
}

- (void)sliderAction:(UISlider *)slider {
    [(GPUImageSepiaFilter *)sepiaFilter setIntensity:slider.value];
}

@end
