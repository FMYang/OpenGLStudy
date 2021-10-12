//
//  FMCameraOpenGLRGBView.h
//  LearnOpenGL
//
//  Created by yfm on 2021/9/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMCameraOpenGLRGBView : UIView

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
