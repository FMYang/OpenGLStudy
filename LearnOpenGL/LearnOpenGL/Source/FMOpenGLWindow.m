//
//  FMOpenGLWindow.m
//  LearnOpenGL
//
//  Created by yfm on 2021/8/25.
//
//  你好，窗口
//  创建OpenGL ES在ios中的窗口（ios中，使用CAEAGLLayer展示openGL绘制的内容）
//

/*
 帧缓存对象：帧缓存对象是渲染命令的目的地。创建帧缓存对象是，你可以精确控制其颜色、深度和模版数据的存储。你可以通过将图像附加到帧缓存来提供此存储。最常见的图像附件是渲染缓存对象。你还可以将OpenGL ES纹理附加到帧缓存的颜色附加点，着意味着任何命令都会渲染到纹理中。
*/

/*
 渲染缓存对象：OpenGLES通过CAEAGLayer类连接到核心动画，这是一种特殊的核心动画层，其内容来自OpenGLES渲染缓存。CoreAnimation将渲染缓存的内容与其他层合并，并在屏幕上显示生成的图像。

 Core Animation与OpenGL ES共享渲染缓存。
*/

#import "FMOpenGLWindow.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

@interface FMOpenGLWindow()

@property (nonatomic) CAEAGLLayer *eagLayer;
// openGL上下文，管理OpenGL状态，openGL是一个大的状态机
@property (nonatomic) EAGLContext *context;
// 渲染缓存（包括颜色缓存、深度测试）ID
@property (nonatomic) GLuint renderBuffer;
// 帧缓存ID（帧缓冲区对象是渲染命令的目的地。帧缓存可以附加渲染缓存）
@property (nonatomic) GLuint frameBuffer;

@end

@implementation FMOpenGLWindow

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self setupLayer];
        [self createContext];
        [self createRenderBufferAndFrameBuffer];
        [self render];
    }
    return self;
}

// 1、设置layer
- (void)setupLayer {
    self.eagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:UIScreen.mainScreen.scale];
    self.eagLayer.opaque = YES;
}

// 2、创建上下文
- (void)createContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(![EAGLContext setCurrentContext:context]) {
        NSLog(@"设置上下文失败");
    }
    self.context = context;
}

// 3、配置渲染缓存和帧缓存
- (void)createRenderBufferAndFrameBuffer {
    // 创建渲染缓存对象，并生成一个独一无二的表示_renderBuffer，第一个参数表示缓存的数量
    glGenRenderbuffers(1, &_renderBuffer);
    // 把创建的缓存_renderBuffer绑定到GL_RENDERBUFFER目标上
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    // 为图层对象分配存储空间。宽度、高度和像素格式取自layer，用于为渲染缓存分配存储空间。
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eagLayer];
    
    // 获取渲染缓存的宽高，来自于eagLayer的宽高
    GLint w, h;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
    NSLog(@"w = %d h = %d", w, h);
    
    glGenRenderbuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // 将渲染缓存附加到帧缓存
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

// 4、清屏并显示
- (void)render {
    // 设置清屏的颜色
    glClearColor(1.0, 1.0, 0.0, 1.0);
    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中。清除的同时，整个颜色缓存都会被填充为glClearColor设置的颜色
    glClear(GL_COLOR_BUFFER_BIT);
    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
