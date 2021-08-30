//
//  SimpleImageFilterVC.h
//  FMGPUImageDemo
//
//  Created by yfm on 2021/8/30.
//

#import <UIKit/UIKit.h>
#import <GPUImage/GPUImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface SimpleImageFilterVC : UIViewController {
    GPUImagePicture *sourcePicture;
    GPUImageOutput<GPUImageInput> *sepiaFilter, *sepiaFilter2;
    
    UISlider *imageSlider;
}

// Image filtering
- (void)setupDisplayFiltering;
- (void)setupImageFilteringToDisk;
- (void)setupImageResampling;

@end

NS_ASSUME_NONNULL_END
