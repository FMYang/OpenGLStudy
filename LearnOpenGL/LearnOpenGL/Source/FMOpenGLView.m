//
//  FMOpenGLView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/8/26.
//

#import "FMOpenGLView.h"

@interface FMOpenGLView()  {
    // 顶点着色器
    GLuint _vertextShader;
    // 片段着色器
    GLuint _fragmentShader;
}
@end

@implementation FMOpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self setupLayer];
        [self createContext];
        [self createRenderBufferAndFrameBuffer];
        [self setViewPort];
        [self render];
    }
    return self;
}

// 1、设置layer
- (void)setupLayer {
    self.eagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:UIScreen.mainScreen.scale];
    self.eagLayer.opaque = YES;
    self.eagLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @(FALSE),
                                        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
}

// 2、创建上下文
- (void)createContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if(![EAGLContext setCurrentContext:context]) {
        NSLog(@"设置上下文失败");
    }
    self.context = context;
}

// 3、配置渲染缓存和帧缓存
- (void)createRenderBufferAndFrameBuffer {
    // 创建渲染缓存对象
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    // 为图层对象分配存储空间。宽度、高度和像素格式取自layer，用于为渲染缓存分配存储空间。
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eagLayer];
    
//    // 获取渲染缓存的宽高，来自于eagLayer的宽高
//    GLint w, h;
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
//    NSLog(@"w = %d h = %d", w, h);
    
    // 创建帧缓存
    glGenRenderbuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // 将渲染缓存附加到帧缓存
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

// 4、设置视口
- (void)setViewPort {
    //  设置视口
    CGFloat scale = UIScreen.mainScreen.scale;
    // OpenGL会使用glViewPort内部的参数来将标准化设备坐标（-1.0到1.0）映射到屏幕坐标，每个坐标都关联了一个屏幕上的点
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height  * scale);
}

// 5、着色器程序
- (void)createProgramWithVertexShader:(NSString *)vertexShaderSource
                       fragmentShader:(NSString *)fragmentShaderSource {
    const GLchar *vertexSource = (GLchar *)[vertexShaderSource UTF8String];
    const GLchar *fragmentSource = (GLchar *)[fragmentShaderSource UTF8String];

    _vertextShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(_vertextShader, 1, &vertexSource, NULL);
    glCompileShader(_vertextShader);
    
    // 校验顶点着色器程序编译状态
    GLint logLength = 0;
    glGetShaderiv(_vertextShader, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(_vertextShader, logLength, &logLength, log);
        NSLog(@"shader compile log:\n%s", log);
        free(log);
    }
    
    _fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(_fragmentShader, 1, &fragmentSource, NULL);
    glCompileShader(_fragmentShader);
    
    // 校验顶点着色器程序编译状态
    GLint alogLength = 0;
    glGetShaderiv(_fragmentShader, GL_INFO_LOG_LENGTH, &alogLength);
    if(logLength > 0) {
        GLchar *log = (GLchar *)malloc(alogLength);
        glGetShaderInfoLog(_fragmentShader, alogLength, &alogLength, log);
        NSLog(@"shader compile log:\n%s", log);
        free(log);
    }
    
    _program = glCreateProgram();
    glAttachShader(_program, _vertextShader);
    glAttachShader(_program, _fragmentShader);
    glLinkProgram(_program);
    
    glDeleteShader(_vertextShader);
    glDeleteShader(_fragmentShader);
}

// 6、渲染
- (void)render {
    
}

- (void)dealloc {
    NSLog(@"%s", __func__);
    if(_frameBuffer) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    if(_renderBuffer) {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
    if(_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

@end
