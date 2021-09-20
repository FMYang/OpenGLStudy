//
//  FMCameraLutView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/19.
//

#import "FMCameraLutView.h"
#import "FMCameraContext.h"

// 通用着色器
NSString *const lutBaseVertexShaderString = SHADER_STRING(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const cameraLutFragmentShaderSource = SHADER_STRING(
    precision lowp float; // 被坑加1
    varying highp vec2 textureCoordinate;
    uniform sampler2D inputImageTexture;
    uniform sampler2D lutImageTexture;
                                                        
    void main()
    {
        vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);

        // 使用lut滤镜
        float blueColor = textureColor.b * 63.0;

        vec2 quad1;
        quad1.y = floor(floor(blueColor) / 8.0);
        quad1.x = floor(blueColor) - (quad1.y * 8.0);

        vec2 quad2;
        quad2.y = floor(ceil(blueColor) / 8.0);
        quad2.x = ceil(blueColor) - (quad2.y * 8.0);

        vec2 texPos1;
        texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
        texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

        vec2 texPos2;
        texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
        texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

        vec4 newColor1 = texture2D(lutImageTexture, texPos1);
        vec4 newColor2 = texture2D(lutImageTexture, texPos2);

        // mix(v1, v2, a) = v1 * (1 - a) + v2 * a
        vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
        gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), 1.0);
    }
);


@interface FMCameraLutView() {
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _program;
    GLuint _vertexShader;
    GLuint _fragmentShader;
    
    GLint w, h;
    GLuint _texture; // 原始图像纹理id
    GLuint _lutTexture; // lut纹理id
}

@end

@implementation FMCameraLutView

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
    const char *vertexSource = (GLchar *)[lutBaseVertexShaderString UTF8String];
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
    const char *fragmentSource = (GLchar *)[cameraLutFragmentShaderSource UTF8String];
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
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_TEST);

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
    [self generateLutTexture:@"香槟.png"];

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
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _lutTexture);
    glUniform1i(glGetUniformLocation(_program, "lutImageTexture"), 2);

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

- (void)generateLutTexture:(NSString *)name {
    UIImage *image = [UIImage imageNamed:name];
    CGImageRef imageRef = [image CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    GLubyte *textureData = (GLubyte *)malloc(width * height * 4);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(textureData, width, height, bitsPerComponent, bytesPerRow, colorSpaceRef, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, imageRef);
    
    glEnable(GL_TEXTURE_2D);
    
    glActiveTexture(GL_TEXTURE2);
    if(!_lutTexture) {
        glGenTextures(1, &_lutTexture);
    }
    glBindTexture(GL_TEXTURE_2D, _lutTexture);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, _lutTexture); //解绑
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    free(textureData);
}

@end
