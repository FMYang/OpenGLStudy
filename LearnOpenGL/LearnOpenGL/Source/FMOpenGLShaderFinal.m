//
//  FMOpenGLShader330.m
//  LearnOpenGL
//
//  Created by yfm on 2021/8/25.
//

#import "FMOpenGLShaderFinal.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// 包含位置和颜色信息的顶点着色器程序
NSString *const vertexShaderSource = SHADER_STRING(
    attribute vec4 aPos;   // 位置变量的属性位置值为 0
    attribute vec3 aColor; // 颜色变量的属性位置值为 1

    varying vec4 FragColor; // 向片段着色器输出一个颜色

    void main()
    {
        gl_Position = aPos;
        FragColor = vec4(aColor, 1.0); // 将ourColor设置为我们从顶点数据那里得到的输入颜色
    }
);

// 片段着色器（in out 分别使用attribute varying）
NSString *const fragmentShaderSource = SHADER_STRING(
    precision mediump float;
    varying vec4 FragColor;

    void main()
    {
        gl_FragColor = FragColor;
    }
);

@interface FMOpenGLShaderFinal() {
    // 顶点着色器
    GLuint vertextShader;
    // 片段着色器
    GLuint fragmentShader;
    // 顶点缓冲对象
    GLuint VBO;
    // 索引缓冲对象
    GLuint EBO;
}

@property (nonatomic) CAEAGLLayer *eagLayer;
// openGL上下文，管理OpenGL状态，openGL是一个大的状态机
@property (nonatomic) EAGLContext *context;
// 渲染缓存（包括颜色缓存、深度测试）ID
@property (nonatomic) GLuint renderBuffer;
// 帧缓存ID（帧缓冲区对象是渲染命令的目的地。帧缓存可以附加渲染缓存）
@property (nonatomic) GLuint frameBuffer;

@end

@implementation FMOpenGLShaderFinal

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self setupLayer];
        [self createContext];
        [self createRenderBufferAndFrameBuffer];
        [self setViewPort];
//        [self render]; // 基本三角形绘制
//        [self render2]; // 使用VAO和索引绘制
        [self render3]; // 绘制更多属性
        
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(screenUpdate)];
        link.preferredFramesPerSecond = 5;
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)screenUpdate {
//    [self render3];
}

// 1、设置layer
- (void)setupLayer {
    self.eagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:UIScreen.mainScreen.scale];
    self.eagLayer.opaque = YES;
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
    
    // 获取渲染缓存的宽高，来自于eagLayer的宽高
    GLint w, h;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
    NSLog(@"w = %d h = %d", w, h);
    
    // 创建帧缓存
    glGenRenderbuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // 将渲染缓存附加到帧缓存
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

- (void)setViewPort {
    //  设置视口，将屏幕坐标变为标准化设备坐标（范围-1 ～ 1）
    CGFloat scale = UIScreen.mainScreen.scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height  * scale);
}

// 4、清屏并显示
- (void)render {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中
    glClear(GL_COLOR_BUFFER_BIT);
    
    //  设置视口，将屏幕坐标变为标准化设备坐标（范围-1 ～ 1）
    CGFloat scale = UIScreen.mainScreen.scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height  * scale);
    
    // 顶点数据
    float vertices[] = {
        0.0f, 0.5f, 0.0f,
        -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f,
    };
    
    /*
     图形渲染管线的第一阶段，顶点着色器。它会在GPU上创建内存用于存储我们的顶点数据
     
     我们通过顶点缓冲对象（Vertex Buffer Objects，VBO）管理这个内存，它会在GPU中存储大量顶点。使用这个对象的好处是我们可以一次性的发送一大批数据到显卡上，而不是每个顶点发送一次。从CPU把数据发送到GPU比较慢，所以尽可能一次性发送尽可能多的数据。
     */
    
    // 创建顶点缓冲对象
    glGenBuffers(1, &VBO);
    // 顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上，复制顶点数组供OpenGL使用
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 把用户定义的数据复制到顶点缓冲中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // 设置顶点属性指针，告诉OpenGL该如何解析顶点数据（应用到逐个顶点属性上）了
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
    // 启用顶点属性
    glEnableVertexAttribArray(0);
        
    GLuint program = [self createProgram];
    glUseProgram(program);

    // 链接程序后设置颜色才生效
    float greenValue = arc4random() % 10 * 1.0 / 10;
    // 获取ourColor的位置，如果返回-1表示没有找到
    int vertexColorLocation = glGetUniformLocation(program, "ourColor");
    // 设置ourColor的值
    glUniform4f(vertexColorLocation, 0.0, greenValue, 0.0, 1.0);
            
    // 绘制三角形
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)render2 {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中
    glClear(GL_COLOR_BUFFER_BIT);
    
    //  设置视口，将屏幕坐标变为标准化设备坐标（范围-1 ～ 1）
    CGFloat scale = UIScreen.mainScreen.scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height  * scale);
    
    // 顶点数据
    float vertices[] = {
        0.5f, 0.5f, 0.0f,   // 右上角
        0.5f, -0.5f, 0.0f,  // 右下角
        -0.5f, -0.5f, 0.0f, // 左下角
        -0.5f, 0.5f, 0.0f   // 左上角
    };

    unsigned int indices[] = { // 注意索引从0开始!
        0, 1, 3, // 第一个三角形
        1, 2, 3  // 第二个三角形
    };
    
    /*
     图形渲染管线的第一阶段，顶点着色器。它会在GPU上创建内存用于存储我们的顶点数据
     
     我们通过顶点缓冲对象（Vertex Buffer Objects，VBO）管理这个内存，它会在GPU中存储大量顶点。使用这个对象的好处是我们可以一次性的发送一大批数据到显卡上，而不是每个顶点发送一次。从CPU把数据发送到GPU比较慢，所以尽可能一次性发送尽可能多的数据。
     */
    
    // 创建顶点缓冲对象
    glGenBuffers(1, &VBO);
    // 顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上，复制顶点数组供OpenGL使用
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 把用户定义的数据复制到顶点缓冲中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // VAO是OpenGL 3.0的特性，2.0无法使用这个特效
    /*
     创建顶点数组对象
     
     可以像顶点缓冲对象那样被绑定，任何随后的顶点属性调用都会储存在这个VAO中。这样的好处就是，当配置顶点属性指针时，你只需要将那些调用执行一次，之后再绘制物体的时候只需要绑定相应的VAO就行了。这使在不同顶点数据和属性配置之间切换变得非常简单，只需要绑定不同的VAO就行了。刚刚设置的所有状态都将存储在VAO中
     */
    GLuint VAO;
    glGenVertexArraysOES(1, &VAO);
    glBindVertexArrayOES(VAO);

    // 索引对象，可以减少绘制的顶点数量
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 设置顶点属性指针，告诉OpenGL该如何解析顶点数据（应用到逐个顶点属性上）了
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
    // 启用顶点属性
    glEnableVertexAttribArray(0);
        
    GLuint program = [self createProgram];
    glUseProgram(program);

    // 链接程序后设置颜色才生效
    float greenValue = arc4random() % 10 * 1.0 / 10;
    // 获取ourColor的位置，如果返回-1表示没有找到
    int vertexColorLocation = glGetUniformLocation(program, "ourColor");
    // 设置uniform类型的ourColor的值
    glUniform4f(vertexColorLocation, 0.0, greenValue, 0.0, 1.0);
    glBindVertexArrayOES(VAO);
    // 索引绘制
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    
    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)render3 {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 顶点数据
    float vertices[] = {
        // 位置              // 颜色
         0.5f, -0.5f, 0.0f,  1.0f, 0.0f, 0.0f,   // 右下
        -0.5f, -0.5f, 0.0f,  0.0f, 1.0f, 0.0f,   // 左下
         0.0f,  0.5f, 0.0f,  0.0f, 0.0f, 1.0f    // 顶部
    };
    
    // 创建顶点缓冲对象
    glGenBuffers(1, &VBO);
    // 顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上，复制顶点数组供OpenGL使用
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 把用户定义的数据复制到顶点缓冲中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint VAO;
    glGenVertexArraysOES(1, &VAO);
    glBindVertexArrayOES(VAO);
    
//    // 设置顶点属性指针，告诉OpenGL该如何解析顶点数据（应用到逐个顶点属性上）了
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
//    // 启用顶点属性
//    glEnableVertexAttribArray(0);
    // 位置属性
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GL_FLOAT), (void*)0);
    glEnableVertexAttribArray(0);
    // 颜色属性
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GL_FLOAT), (void*)(3* sizeof(GL_FLOAT)));
    glEnableVertexAttribArray(1);
        
    GLuint program = [self createProgram];
    glUseProgram(program);
    glBindVertexArrayOES(VAO);
    // 索引绘制
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];

}

- (GLuint)createProgram {
    // 创建顶点着色器
    vertextShader = glCreateShader(GL_VERTEX_SHADER);
    const GLchar *vertexSource = (GLchar *)[vertexShaderSource UTF8String];
    // 将着色器源码附加到着色器对象上
    glShaderSource(vertextShader, 1, &vertexSource, NULL);
    // 编译
    glCompileShader(vertextShader);
    
#if DEBUG
    // 校验顶点着色器程序编译状态
    GLint logLength = 0;
    glGetShaderiv(vertextShader, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(vertextShader, logLength, &logLength, log);
        NSLog(@"shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    // 创建顶点着色器
    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    // 将着色器源码附加到着色器对象上
    const GLchar *fragmentSource = (GLchar *)[fragmentShaderSource UTF8String];
    glShaderSource(fragmentShader, 1, &fragmentSource, NULL);
    glCompileShader(fragmentShader);

#if DEBUG
    // 校验片段着色器程序编译状态
    GLint alogLength = 0;
    glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &alogLength);
    if(logLength > 0) {
        GLchar *log = (GLchar *)malloc(alogLength);
        glGetShaderInfoLog(fragmentShader, alogLength, &alogLength, log);
        NSLog(@"shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    // 创建程序
    GLuint program = glCreateProgram();
    
    // 把着色器对象附加到程序对象
    glAttachShader(program, vertextShader);
    glAttachShader(program, fragmentShader);
    // 链接程序
    glLinkProgram(program);
    
    glDeleteShader(vertextShader);
    glDeleteShader(fragmentShader);
    
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if(linkSuccess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"error %@", messageStr);
    }
    
    return program;
}

@end
