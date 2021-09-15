//
//  GPUImageView.h
//  GPUImage
//
//  Created by yfm on 2021/9/15.
//

#import <UIKit/UIKit.h>
#import "GPUImageContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageView : UIView <GPUImageInput> {
    GPUImageRotationMode inputRotation;
}

@property(nonatomic) BOOL enabled;

@property(readonly, nonatomic) CGSize sizeInPixels;

@end

NS_ASSUME_NONNULL_END
