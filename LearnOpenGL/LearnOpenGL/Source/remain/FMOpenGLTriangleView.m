////
////  FMOpenGLTriangleView.m
////  LearnOpenGL1(三角形)
////
////  Created by yfm on 2021/8/23.
////
//
//#import "FMOpenGLTriangleView.h"
//#import <OpenGLES/EAGL.h>
//#import <OpenGLES/ES2/gl.h>
//
////// 顶点着色器
////const char *vertexShaderSource = "#version 330 core\n"
////    "layout (location = 0) in vec3 aPos;\n"
////    "void main()\n"
////    "{\n"
////    "   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
////    "}\0";
////
////const char *fragmentShaderSource = "#version 330 core\n"
////    "out vec4 FragColor;\n"
////    "void main()\n"
////    "{\n"
////    "   FragColor = vec4(1.0, 0.5, 0.2, 1.0);\n"
////    "}\0";
//
//// 顶点着色器
//const char *vertexShaderSource = "attribute vec4 position;\n"
//    "void main()\n"
//    "{\n"
//    "   gl_Position = position;\n"
//    "}\0";
//
//// 片段着色器
//const char *fragmentShaderSource = "void main()\n"
//    "{\n"
//    "   gl_FragColor = vec4(1.0, 0.5, 0.2, 1.0);\n"
//    "}\n\0";
//
//@interface FMOpenGLTriangleView() {
//    GLuint _vertexShader;
//    GLuint _fragmentShader;
//    GLuint _VBO;
//    GLuint _renderBuffer;
//    GLuint _frameBuffer;
//}
//
//// iOS OpenGL窗口
//@property (nonatomic, strong) CAEAGLLayer *eagLayer;
//@property (nonatomic, strong) EAGLContext *context;
//
//@end
//
//@implementation FMOpenGLTriangleView
//
//// 1、修改layer类型为openGL需要的layer类型
//+ (Class)layerClass {
//    return [CAEAGLLayer class];
//}
//
//- (void)setupLayer {
//    self.eagLayer = (CAEAGLLayer *)self.layer;
//    [self setContentScaleFactor:UIScreen.mainScreen.scale];
//    self.eagLayer.opaque = YES;
//}
//
//- (void)layoutSubviews {
//    [self setupLayer];
//    [self createOpenGLContext];
//    [self createRenderBuffer];
//    [self createFrameBuffer];
//
//    [self createProgram];
//    [self render];
//}
//
//// 2、创建openGL上下文
//- (void)createOpenGLContext {
//    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
//    if(![EAGLContext setCurrentContext:context]) {
//        NSLog(@"Fail to set current context");
//    }
//    self.context = context;
//}
//
//// 3、创建渲染缓存
//- (void)createRenderBuffer {
//    glGenRenderbuffers(1, &_renderBuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
//    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eagLayer];
//}
//
//// 4、创建帧缓存
//- (void)createFrameBuffer {
//    glGenFramebuffers(1, &_frameBuffer);
//    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
//}
//
//- (void)render {
//    glClearColor(1.0, 1.0, 1.0, 1.0); // 白色
//    glClear(GL_COLOR_BUFFER_BIT);
//
//    CGFloat scale = UIScreen.mainScreen.scale;
//    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
//
//    float vertices[] = {
//        -0.5f, -0.5f, 0.0f,
//         0.5f, -0.5f, 0.0f,
//         0.0f,  0.5f, 0.0f
//    };
//
//    glGenBuffers(1, &_VBO);
//    glBindBuffer(GL_ARRAY_BUFFER, _VBO);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
//
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
//    glEnableVertexAttribArray(0);
//
//    GLuint program = [self createProgram];
//    glUseProgram(program);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
//
//    [self.context presentRenderbuffer:GL_RENDERBUFFER];
//}
//
//- (GLuint)createProgram {
//    // 顶点着色器
//    _vertexShader = glCreateShader(GL_VERTEX_SHADER);
//    glShaderSource(_vertexShader, 1, &vertexShaderSource, NULL);
//    glCompileShader(_vertexShader);
//
//    // 片段着色器
//    _fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
//    glShaderSource(_fragmentShader, 1, &fragmentShaderSource, NULL);
//    glCompileShader(_fragmentShader);
//
//    GLuint shaderProgram;
//    shaderProgram = glCreateProgram();
//
//    glAttachShader(shaderProgram, _vertexShader);
//    glAttachShader(shaderProgram, _fragmentShader);
//    glLinkProgram(shaderProgram);
//
//    glDeleteShader(_vertexShader);
//    glDeleteShader(_fragmentShader);
//
//    GLint linkSuccess;
//    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &linkSuccess);
//    if(linkSuccess == GL_FALSE) {
//        GLchar message[256];
//        glGetProgramInfoLog(shaderProgram, sizeof(message), 0, &message[0]);
//        NSString *messageStr = [NSString stringWithUTF8String:message];
//        NSLog(@"error %@", messageStr);
//        return -1;
//    }
//
//    return shaderProgram;
//}
//
//@end
