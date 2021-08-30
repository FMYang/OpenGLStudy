//
//  FMOpenGLTriangle.m
//  LearnOpenGL
//
//  Created by yfm on 2021/8/25.
//
//  你好，三角形

#import "FMOpenGLTriangle.h"

// 如果我们打算做渲染的话，现代OpenGL需要至少设置一个顶点着色器和一个片段着色器
// 顶点着色器
NSString *const triangleVertexShaderSource = SHADER_STRING(
    attribute vec4 position;
    void main()
    {
       gl_Position = position;
    }
);

// 片段着色器
NSString *const triangleFragmentShaderSource = SHADER_STRING(
    void main()
    {
       gl_FragColor = vec4(1.0, 0.5, 0.2, 1.0);
    }
);

@interface FMOpenGLTriangle()
// 顶点缓冲对象
@property (nonatomic) GLuint VBO;
// 索引缓冲对象
@property (nonatomic) GLuint EBO;

@end

@implementation FMOpenGLTriangle

//+ (Class)layerClass {
//    return [CAEAGLLayer class];
//}
//
//- (instancetype)initWithFrame:(CGRect)frame {
//    if(self = [super initWithFrame:frame]) {
//        [self setupLayer];
//        [self createContext];
//        [self createRenderBufferAndFrameBuffer];
//        [self render];
//    }
//    return self;
//}
//
//// 1、设置layer
//- (void)setupLayer {
//    self.eagLayer = (CAEAGLLayer *)self.layer;
//    [self setContentScaleFactor:UIScreen.mainScreen.scale];
//    self.eagLayer.opaque = YES;
//}
//
//// 2、创建上下文
//- (void)createContext {
//    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
//    if(![EAGLContext setCurrentContext:context]) {
//        NSLog(@"设置上下文失败");
//    }
//    self.context = context;
//}
//
//// 3、配置渲染缓存和帧缓存
//- (void)createRenderBufferAndFrameBuffer {
//    // 创建渲染缓存对象
//    glGenRenderbuffers(1, &_renderBuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
//    // 为图层对象分配存储空间。宽度、高度和像素格式取自layer，用于为渲染缓存分配存储空间。
//    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eagLayer];
//
//    // 获取渲染缓存的宽高，来自于eagLayer的宽高
//    GLint w, h;
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
//    NSLog(@"w = %d h = %d", w, h);
//
//    // 创建帧缓存
//    glGenRenderbuffers(1, &_frameBuffer);
//    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
//
//    // 将渲染缓存附加到帧缓存
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
//}
//
//// 4、清屏并显示
//- (void)render {
//    glClearColor(1.0, 1.0, 1.0, 1.0);
//    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中
//    glClear(GL_COLOR_BUFFER_BIT);
//
//    //  设置视口，将屏幕坐标变为标准化设备坐标（范围-1 ～ 1）
//    CGFloat scale = UIScreen.mainScreen.scale;
//    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height  * scale);
//
//    // 顶点数据
//    GLfloat vertices[] = {
//        -0.5f, -0.5f, 0.0f,
//         0.5f, -0.5f, 0.0f,
//         0.0f,  0.5f, 0.0f
//    };
//
//    /*
//     图形渲染管线的第一阶段，顶点着色器。它会在GPU上创建内存用于存储我们的顶点数据
//
//     我们通过顶点缓冲对象（Vertex Buffer Objects，VBO）管理这个内存，它会在GPU中存储大量顶点。使用这个对象的好处是我们可以一次性的发送一大批数据到显卡上，而不是每个顶点发送一次。从CPU把数据发送到GPU比较慢，所以尽可能一次性发送尽可能多的数据。
//     */
//
//    // 创建顶点顶点缓冲对象
//    glGenBuffers(1, &VBO);
//    // 顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上，复制顶点数组供OpenGL使用
//    glBindBuffer(GL_ARRAY_BUFFER, VBO);
//    // 把用户定义的数据复制到顶点缓冲中
//    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
//
//    // VAO是OpenGL 3.0的特性，2.0无法使用这个特效
////    GLuint VAO;
////    glGenVertexArrays(1, &VAO);
////    glBindVertexArray(VAO);
//
//    // 设置顶点属性指针，告诉OpenGL该如何解析顶点数据（应用到逐个顶点属性上）了
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
//    // 启用顶点属性
//    glEnableVertexAttribArray(0);
//
//    GLuint program = [self createProgram];
//    glUseProgram(program);
//
//    // 绘制三角形
//    glDrawArrays(GL_TRIANGLES, 0, 3);
//
//    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
//    [self.context presentRenderbuffer:GL_RENDERBUFFER];
//}
//
//- (GLuint)createProgram {
//    // 创建顶点着色器
//    vertextShader = glCreateShader(GL_VERTEX_SHADER);
//    // 将着色器源码附加到着色器对象上
//    glShaderSource(vertextShader, 1, &vertexShaderSource, NULL);
//    // 编译
//    glCompileShader(vertextShader);
//
//    // 创建顶点着色器
//    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
//    // 将着色器源码附加到着色器对象上
//    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
//    glCompileShader(fragmentShader);
//
//    // 创建程序
//    GLuint program = glCreateProgram();
//
//    // 把着色器对象附加到程序对象
//    glAttachShader(program, vertextShader);
//    glAttachShader(program, fragmentShader);
//    // 链接程序
//    glLinkProgram(program);
//
//    glDeleteShader(vertextShader);
//    glDeleteShader(fragmentShader);
//
//    GLint linkSuccess;
//    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
//    if(linkSuccess == GL_FALSE) {
//        GLchar message[256];
//        glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
//        NSString *messageStr = [NSString stringWithUTF8String:message];
//        NSLog(@"error %@", messageStr);
//    }
//
//    return program;
//}

- (void)render {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 顶点数据数组
    GLfloat vertices[] = {
        -0.5, -0.5, 0.0,
        0.5, -0.5, 0.0,
        0.0, 0.5, 0.0
    };
    
    // 生成顶点缓冲对象和对象的唯一ID（VBO）
    glGenBuffers(1, &_VBO);
    // 缓冲绑定到GL_ARRAY_BUFFER目标上，OpenGL有很多缓冲对象类型，顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER
    glBindBuffer(GL_ARRAY_BUFFER, _VBO);
    // 将顶点数据复制到顶点缓冲的内存中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
    glEnableVertexAttribArray(0);
    
    [self createProgramWithVertexShader:triangleVertexShaderSource fragmentShader:triangleFragmentShaderSource];
    glUseProgram(self.program);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    [self.context presentRenderbuffer:self.renderBuffer];
}

@end
