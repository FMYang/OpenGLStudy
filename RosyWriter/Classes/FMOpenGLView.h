//
//  FMOpenGLView.h
//  RosyWriterOpenGL
//
//  Created by yfm on 2021/9/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMOpenGLView : UIView

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)flushPixelBufferCache;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
