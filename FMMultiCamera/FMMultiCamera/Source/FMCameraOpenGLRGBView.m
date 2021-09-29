//
//  FMCameraOpenGLRGBView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/19.

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#import "FMCameraOpenGLRGBView.h"
#import "FMCameraContext.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// 通用着色器
NSString *const baseVertexShaderString = SHADER_STRING(
   precision mediump float;
   attribute vec2 position;
   attribute vec2 textureCoord;

   varying vec2 aTextureCoord;
   varying vec2 aPosition;
                                                         
   void main()
   {
      gl_Position = vec4(position, 0.0, 1.0);
   
      aTextureCoord = textureCoord;
      aPosition = position;
   }
);

NSString *const baseFragmentShaderString = SHADER_STRING(
    precision mediump float;
    varying vec2 aTextureCoord;
    varying vec2 aPosition;
    
    uniform sampler2D textureIndex1;
    uniform sampler2D textureIndex2;

    void main()
    {
        if(aPosition.y >= 0.0) {
            gl_FragColor = texture2D(textureIndex1, aTextureCoord);
        } else {
            gl_FragColor = texture2D(textureIndex2, aTextureCoord);
        }
    }
);

@interface FMCameraOpenGLRGBView() {
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _program;
    GLuint _vertexShader;
    GLuint _fragmentShader;
    
    GLint w, h;
    GLuint _texture1; // 纹理id
    GLuint _texture2; // 纹理id
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

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer index:(int)index {
    [FMCameraContext useImageProcessingContext];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    float vertices1[] = {
        -0.6, 0.0,
        0.6, 0.0,
        -0.6, 1.0,
        0.6, 1.0
    };
    
    float vertices2[] = {
        -0.6, -1.0,
        0.6, -1.0,
        -0.6, 0.0,
        0.6, 0.0
    };
    
    float textureCoord[] = {
        1.0, 1.0,
        1.0, 0.0,
        0.0, 1.0,
        0.0, 0.0,
    };
    
    float textureCoord1[] = {
        1.0, 0.0,
        1.0, 1.0,
        0.0, 0.0,
        0.0, 1.0,
    };

    [self generateTexture:pixelBuffer index:index];

    glUseProgram(_program);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _texture1);
    glUniform1i(glGetUniformLocation(_program, "textureIndex1"), 1);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _texture2);
    glUniform1i(glGetUniformLocation(_program, "textureIndex2"), 2);

    GLuint textureCoordLoc = glGetAttribLocation(_program, "textureCoord");
    glEnableVertexAttribArray(textureCoordLoc);
    
    glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, textureCoord);
    
    GLuint positionLoc = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(positionLoc);
    
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertices1);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, textureCoord1);
    
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertices2);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glBindRenderbuffer(GL_RENDERER, _renderBuffer);
    [FMCameraContext.shared presentBufferForDisplay];
}

- (void)generateTexture:(CVPixelBufferRef)pixelBuffer index:(int)index {
    int bufferHeight = (int) CVPixelBufferGetHeight(pixelBuffer);

    if(index == 1) {
        if(!_texture1) {
            glGenTextures(1, &_texture1);
        }
        glBindTexture(GL_TEXTURE_2D, _texture1);
    } else {
        if(!_texture2) {
            glGenTextures(1, &_texture2);
        }
        glBindTexture(GL_TEXTURE_2D, _texture2);
    }
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    // 复制图片像素的颜色数据到绑定的纹理缓存中。
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

@end
