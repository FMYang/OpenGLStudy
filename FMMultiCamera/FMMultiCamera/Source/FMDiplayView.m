//
//  FMDiplayView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/21.
//

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#import "FMDiplayView.h"
#import "FMCameraContext.h"

// 通用着色器
NSString *const displayVertexShaderString = SHADER_STRING(
 precision lowp float;
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const displayFragmentShaderString = SHADER_STRING(
 precision lowp float;
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);


@interface FMDiplayView() {
    FMFrameBuffer *inputFrameBuffer;
    
    GLuint displayRenderbuffer, displayFramebuffer;
    GLuint _program;
    GLuint _vertexShader;
    GLuint _fragmentShader;
    
    GLint backingWidth, backingHeight;
}

@property (nonatomic) FMDisplayType displayType;

@end

@implementation FMDiplayView

- (void)dealloc {
    NSLog(@"%s", __func__);
    if(_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    if(displayFramebuffer) {
        glDeleteFramebuffers(1, &displayFramebuffer);
        displayFramebuffer = 0;
    }
    if(displayRenderbuffer) {
        glDeleteRenderbuffers(1, &displayRenderbuffer);
        displayRenderbuffer = 0;
    }
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame type:(FMDisplayType)type {
    if(self = [super initWithFrame:frame]) {
        _displayType = type;
        [self setupLayer];
        [self createProgram];
        [self createDisplayFramebuffer];
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

- (void)createProgram {
    [FMCameraContext useImageProcessingContext];

    _vertexShader = glCreateShader(GL_VERTEX_SHADER);
    const char *vertexSource = (GLchar *)[displayVertexShaderString UTF8String];
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
    const char *fragmentSource = (GLchar *)[displayFragmentShaderString UTF8String];
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

- (void)createDisplayFramebuffer {
    [FMCameraContext useImageProcessingContext];
    
    glGenFramebuffers(1, &displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    glGenRenderbuffers(1, &displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    
    [[[FMCameraContext shared] context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    NSLog(@"Backing width: %d, height: %d", backingWidth, backingHeight);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRenderbuffer);
}

- (void)setDisplayFramebuffer {
    if(!displayFramebuffer) {
        [self createDisplayFramebuffer];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
}

#pragma mark --
- (void)setInputFrameBuffer:(FMFrameBuffer *)frameBuffer {
    inputFrameBuffer = frameBuffer;
    
    [self render];
}

- (void)render {
    [FMCameraContext useImageProcessingContext];

    GLfloat vertex[] = {
        -1.0, -0.82,
        1.0, -0.82,
        -1.0, 0.82,
        1.0, 0.82
    };
    
    // 纹理坐标
    static const GLfloat noRotateTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };

    glUseProgram(_program);
    [self setDisplayFramebuffer];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [inputFrameBuffer texture]);

    GLuint positionLoc = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(positionLoc);
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertex);

    GLuint textureCoordLoc = glGetAttribLocation(_program, "inputTextureCoordinate");
    glEnableVertexAttribArray(textureCoordLoc);
    glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, noRotateTextureCoordinates);

    glUniform1i(glGetUniformLocation(_program, "inputImageTexture"), 4);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [FMCameraContext.shared presentBufferForDisplay];

}

@end
