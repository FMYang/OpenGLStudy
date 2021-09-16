//
//  GPUImageView.h
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import <UIKit/UIKit.h>
#import "GPUImageContext.h"

typedef NS_ENUM(NSUInteger, GPUImageFillModeType) {
    kGPUImageFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio
    kGPUImageFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color
    kGPUImageFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view
};

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageView : UIView <GPUImageInput> {
    GPUImageRotationMode inputRotation;
}

@property(nonatomic) BOOL enabled;

@property(readwrite, nonatomic) GPUImageFillModeType fillMode;

@property(readonly, nonatomic) CGSize sizeInPixels;

@end

NS_ASSUME_NONNULL_END
