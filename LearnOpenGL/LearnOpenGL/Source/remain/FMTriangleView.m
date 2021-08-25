////
////  FMTriangleView.m
////  LearnOpenGL1(三角形)
////
////  Created by yfm on 2021/8/23.
////
//
//#import "FMTriangleView.h"
//#import <OpenGLES/EAGL.h>
//#import <OpenGLES/ES2/gl.h>
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
//    "   gl_FragColor = vec4(0.5, 0.5, 0.5, 1.0);\n"
//    "}\n\0";
//
//
//@interface FMTriangleView() {
//    GLuint _renderBuffer;
//    GLuint _frameBuffer;
//    GLuint _program;
//}
//
//@property (nonatomic, strong) EAGLContext *context;
//@property (nonatomic, strong) CAEAGLLayer *eagLayer;
//
//@end
//
//@implementation FMTriangleView
//
//- (void)layoutSubviews {
//    [self setupLayer];
//    [self createOpenGLContext];
//    [self createRenderBuffer];
//    [self createFrameBuffer];
//    [self render];
//}
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
//// 5、编译链接着色器程序
//- (BOOL)createProgramWithShaders {
//    GLuint verShader, fragShader;
//    
//    _program = glCreateProgram();
//    
//    // 编译
//    verShader = glCreateShader(GL_VERTEX_SHADER);
//    glShaderSource(verShader, 1, &vertexShaderSource, NULL);
//    glCompileShader(verShader);
//
//    fragShader = glCreateShader(GL_FRAGMENT_SHADER);
//    glShaderSource(fragShader, 1, &fragmentShaderSource, NULL);
//    glCompileShader(fragShader);
//
//    glAttachShader(_program, verShader);
//    glAttachShader(_program, fragShader);
//    
//    glDeleteShader(verShader);
//    glDeleteShader(fragShader);
//    
//    glLinkProgram(_program);
//    GLint linkSuccess;
//    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
//    if(linkSuccess == GL_FALSE) {
//        GLchar message[256];
//        glGetProgramInfoLog(_program, sizeof(message), 0, &message[0]);
//        NSString *messageStr = [NSString stringWithUTF8String:message];
//        NSLog(@"error %@", messageStr);
//        return NO;
//    }
//    
//    return YES;
//}
//
//// 6、传入顶点数据，绘制三角形
//- (void)render {
//    // 白色
//    glClearColor(1.0, 1.0, 1.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT);
//    
//    CGFloat scale = UIScreen.mainScreen.scale;
//    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
//    
//    BOOL buildProgramSuccess = [self createProgramWithShaders];
//    if(!buildProgramSuccess) {
//        NSLog(@"着色器程序创建失败");
//        return;
//    }
//    glUseProgram(_program);
//    
//    GLfloat attrArr[] = {
//        -0.5, 0.0, 0.0,
//        0.5, 0.0, 0.0,
//        0.0, 0.5, 0.0,
//    };
//    
//    GLuint attrBuffer;
//    glGenBuffers(1, &attrBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
//    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
//    
//    GLuint postion = glGetAttribLocation(_program, "position");
//    
//    glVertexAttribPointer(postion, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), NULL);
//    glEnableVertexAttribArray(postion);
//    
//    glDrawArrays(GL_TRIANGLES, 0, 3);
//    
//    [self.context presentRenderbuffer:GL_RENDERBUFFER];
//}
//
//@end
