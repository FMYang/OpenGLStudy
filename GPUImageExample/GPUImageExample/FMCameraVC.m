//
//  FMCameraVC.m
//  GPUImageExample
//
//  Created by yfm on 2021/9/24.
//

#import "FMCameraVC.h"
#import <GPUImage/GPUImage.h>

@interface FMCameraVC ()
@property (nonatomic, strong) GPUImageVideoCamera *camera;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, copy) NSString *filterName;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic) float sliderValue;
@property (nonatomic) GPUImageOutput<GPUImageInput> *curFilter;
@property (nonatomic) UIButton *closeBtn;
@end

@implementation FMCameraVC

- (instancetype)initWithFilterName:(NSString *)filterName {
    if(self = [super init]) {
        _filterName = filterName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _gpuImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_gpuImageView];
    [self.view addSubview:self.slider];
    [self.view addSubview:self.closeBtn];

    _camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    self.curFilter = [self filter];
    [_camera addTarget:self.curFilter];
    
    [self.curFilter addTarget:_gpuImageView];
    
    [self.camera startCameraCapture];
}

- (GPUImageOutput<GPUImageInput> *)filter {
    if([self.filterName isEqualToString:@"GPUImageBrightnessFilter"]) {
        GPUImageBrightnessFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageExposureFilter"]) {
        GPUImageExposureFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageContrastFilter"]) {
        GPUImageContrastFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageSaturationFilter"]) {
        GPUImageSaturationFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageGammaFilter"]) {
        GPUImageGammaFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageEmbossFilter"]) {
        GPUImageEmbossFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageEmbossFilter"]) {
        GPUImageEmbossFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageKuwaharaFilter"]) {
        GPUImageKuwaharaFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageToonFilter"]) {
        GPUImageToonFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageSketchFilter"]) {
        GPUImageSketchFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageHighlightShadowFilter"]) {
        GPUImageHighlightShadowFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageMonochromeFilter"]) {
        GPUImageMonochromeFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        [filter setColorRed:1.0 green:0.0 blue:0.0];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageColorInvertFilter"]) {
        GPUImageColorInvertFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else if([self.filterName isEqualToString:@"GPUImageGrayscaleFilter"]) {
        GPUImageGrayscaleFilter *filter = [[NSClassFromString(self.filterName) alloc] init];
        return filter;
    } else {
        return nil;
    }
}

- (void)sliderValueDidChange:(UISlider *)slider {
    if([self.curFilter isKindOfClass:GPUImageBrightnessFilter.class]) {
        ((GPUImageBrightnessFilter *)self.curFilter).brightness = slider.value;
    } else if([self.curFilter isKindOfClass:GPUImageExposureFilter.class]) {
        ((GPUImageExposureFilter *)self.curFilter).exposure = slider.value;
    } else if([self.curFilter isKindOfClass:GPUImageContrastFilter.class]) {
        CGFloat value = slider.value * 4.0;
        ((GPUImageContrastFilter *)self.curFilter).contrast = value;
    } else if([self.curFilter isKindOfClass:GPUImageSaturationFilter.class]) {
        CGFloat value = slider.value * 2.0;
        ((GPUImageSaturationFilter *)self.curFilter).saturation = value;
    } else if([self.curFilter isKindOfClass:GPUImageGammaFilter.class]) {
        CGFloat value = slider.value * 3.0;
        ((GPUImageGammaFilter *)self.curFilter).gamma = value;
    } else if([self.curFilter isKindOfClass:GPUImageEmbossFilter.class]) {
        CGFloat value = slider.value * 4.0;
        ((GPUImageEmbossFilter *)self.curFilter).intensity = value;
    } else if([self.curFilter isKindOfClass:GPUImageKuwaharaFilter.class]) {
        CGFloat value = slider.value * 3 + 3;
        ((GPUImageKuwaharaFilter *)self.curFilter).radius = value;
    } else if([self.curFilter isKindOfClass:GPUImageToonFilter.class]) {
        CGFloat value = slider.value * 5 + 10;
        ((GPUImageToonFilter *)self.curFilter).quantizationLevels = value;
    } else if([self.curFilter isKindOfClass:GPUImageSketchFilter.class]) {
        CGFloat value = slider.value;
        ((GPUImageSketchFilter *)self.curFilter).edgeStrength = value;
    } else if([self.curFilter isKindOfClass:GPUImageHighlightShadowFilter.class]) {
        CGFloat value = slider.value;
        ((GPUImageHighlightShadowFilter *)self.curFilter).shadows = value;
        ((GPUImageHighlightShadowFilter *)self.curFilter).highlights = value;
    } else if([self.curFilter isKindOfClass:GPUImageMonochromeFilter.class]) {
        CGFloat value = slider.value;
        ((GPUImageMonochromeFilter *)self.curFilter).intensity = value;
    } else if([self.curFilter isKindOfClass:GPUImageColorInvertFilter.class]) {
    } else if([self.curFilter isKindOfClass:GPUImageGrayscaleFilter.class]) {
    }
}

- (UISlider *)slider {
    if(!_slider) {
        _slider = [[UISlider alloc] initWithFrame:CGRectMake(40, UIScreen.mainScreen.bounds.size.height - 60 - 34, UIScreen.mainScreen.bounds.size.width - 80, 40)];
        _slider.maximumTrackTintColor = UIColor.whiteColor;
        _slider.minimumTrackTintColor = UIColor.blueColor;
        _slider.minimumValue = 0.0;
        _slider.maximumValue = 1.0;
        _slider.value = 0.5;
        [_slider addTarget:self action:@selector(sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}

- (UIButton *)closeBtn {
    if(!_closeBtn) {
        _closeBtn = [[UIButton alloc] init];
        _closeBtn.frame = CGRectMake(0, 40, 100, 44);
        [_closeBtn setTitle:@"close" forState:UIControlStateNormal];
        [_closeBtn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (void)closeAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
