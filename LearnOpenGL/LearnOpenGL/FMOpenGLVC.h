//
//  FMOpenGLVC.h
//  LearnOpenGL
//
//  Created by yfm on 2021/8/26.
//

#import <UIKit/UIKit.h>
#import "FMTriangleView.h"
#import "FMOpenGLTriangleView.h"
#import "FMOpenGLWindow.h"
#import "FMOpenGLTriangle.h"
#import "FMOpenGLShader.h"
#import "FMOpenGLShaderFinal.h"
#import "FMOpenGLTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface FMOpenGLVC : UIViewController

- (instancetype)initWithClassName:(NSString *)className;

@end

NS_ASSUME_NONNULL_END
