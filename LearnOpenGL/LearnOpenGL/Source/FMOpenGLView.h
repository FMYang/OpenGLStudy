//
//  FMOpenGLView.h
//  LearnOpenGL
//
//  Created by yfm on 2021/8/26.
//
//  将创建iOS OpenGL窗口环境的代码抽出来，子类只处理自己的绘制代码，避免代码重复

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMOpenGLView : UIView

// openGL上下文，管理OpenGL状态，openGL是一个大的状态机
@property (nonatomic) EAGLContext *context;
// 图层layer
@property (nonatomic) CAEAGLLayer *eagLayer;
// 渲染缓存（包括颜色缓存、深度测试）ID
@property (nonatomic) GLuint renderBuffer;
// 帧缓存ID（帧缓冲区对象是渲染命令的目的地。帧缓存可以附加渲染缓存）
@property (nonatomic) GLuint frameBuffer;

// 着色器程序对象
@property (nonatomic) GLuint program;

// 创建着色器程序
- (void)createProgramWithVertexShader:(NSString *)vertexShaderSource
                       fragmentShader:(NSString *)fragmentShaderSource;

// 绘制方法，子类实现
- (void)render;

@end

NS_ASSUME_NONNULL_END
