//
//  FMDiplayView.h
//  LearnOpenGL
//
//  Created by yfm on 2021/9/21.
//

#import <UIKit/UIKit.h>
#import "FMFrameBuffer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FMDisplayType) {
    FMDisplayType_upAndDownSplit, // 上下分割
    FMDisplayType_picInPic, // 画中画
};

@interface FMDiplayView : UIView

- (instancetype)initWithFrame:(CGRect)frame type:(FMDisplayType)type;
- (void)setInputFrameBuffer:(FMFrameBuffer *)frameBuffer;

@end

NS_ASSUME_NONNULL_END
