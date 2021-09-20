//
//  FMCameraOpenGLView.h
//  LearnOpenGL
//
//  Created by yfm on 2021/9/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMCameraOpenGLView : UIView

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
