//
//  FMCameraOpenGLRGBView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/19.
//

#import "FMCameraOpenGLRGBView.h"
#import "FMCameraContext.h"

// 通用着色器
NSString *const baseVertexShaderString = SHADER_STRING(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const baseFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

@interface FMCameraOpenGLRGBView() {
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _program;
    GLuint _vertexShader;
    GLuint _fragmentShader;
    
    GLint w, h;
    GLuint _texture; // 纹理id
}

@end

@implementation FMCameraOpenGLRGBView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self setupLayer];
        [self createProgram];
        [self createFrameBuffer];
    }
    return self;
}

- (void)setupLayer {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:UIScreen.mainScreen.scale];
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @(NO),
                                     kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
}

- (void)createFrameBuffer {
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [FMCameraContext.shared.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &w);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &h);
    NSLog(@"w = %d h = %d", w, h);

    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    glViewport(0, 0, w, h);
}

- (void)createProgram {
    [FMCameraContext useImageProcessingContext]; // 一定要

    _vertexShader = glCreateShader(GL_VERTEX_SHADER);
    const char *vertexSource = (GLchar *)[baseVertexShaderString UTF8String];
    glShaderSource(_vertexShader, 1, &vertexSource, NULL);
    glCompileShader(_vertexShader);

    GLint logLength = 0;
    glGetShaderiv(_vertexShader, GL_INFO_LOG_LENGTH, &logLength);
    if(logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(_vertexShader, logLength, &logLength, log);
        NSLog(@"vertexShader compile log:\n%s", log);
        free(log);
    }

    _fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    const char *fragmentSource = (GLchar *)[baseFragmentShaderString UTF8String];
    glShaderSource(_fragmentShader, 1, &fragmentSource, NULL);
    glCompileShader(_fragmentShader);

    GLint alogLength = 0;
    glGetShaderiv(_fragmentShader, GL_INFO_LOG_LENGTH, &alogLength);
    if(logLength > 0) {
        GLchar *log = (GLchar *)malloc(alogLength);
        glGetShaderInfoLog(_fragmentShader, alogLength, &alogLength, log);
        NSLog(@"fragmentShader compile log:\n%s", log);
        free(log);
    }

    _program = glCreateProgram();
    glAttachShader(_program, _vertexShader);
    glAttachShader(_program, _fragmentShader);
    glLinkProgram(_program);

    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);

    glDeleteShader(_vertexShader);
    glDeleteShader(_fragmentShader);
}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [FMCameraContext useImageProcessingContext];

    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // 顶点坐标
    GLfloat vertex[] = {
        -1.0, -1.0,
        1.0, -1.0,
        -1.0, 1.0,
        1.0, 1.0
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    // 纹理坐标
    static const GLfloat textureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };

    [self generateTexture:pixelBuffer];

    glUseProgram(_program);

    GLuint positionLoc = glGetAttribLocation(_program, "position");
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertex);
    glEnableVertexAttribArray(positionLoc);

    GLuint textureCoordLoc = glGetAttribLocation(_program, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureCoordLoc);
    glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, rotateRightTextureCoordinates);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(glGetUniformLocation(_program, "inputImageTexture"), 1);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glBindRenderbuffer(GL_RENDERER, _renderBuffer);
    [FMCameraContext.shared presentBufferForDisplay];
}

- (void)generateTexture:(CVPixelBufferRef)pixelBuffer {
    int bufferWidth = (int) CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int) CVPixelBufferGetHeight(pixelBuffer);
    
    glActiveTexture(GL_TEXTURE1);
    if(!_texture) {
        glGenTextures(1, &_texture);
    }
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

@end
