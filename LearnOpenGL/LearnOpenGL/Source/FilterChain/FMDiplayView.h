//
//  FMDiplayView.h
//  LearnOpenGL
//
//  Created by yfm on 2021/9/21.
//

#import <UIKit/UIKit.h>
#import "FMFrameBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FMDiplayView : UIView

- (void)setInputFrameBuffer:(FMFrameBuffer *)frameBuffer;

@end

NS_ASSUME_NONNULL_END
