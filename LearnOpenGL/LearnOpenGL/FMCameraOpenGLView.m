//
//  FMCameraOpenGLView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/18.
//

#import "FMCameraOpenGLView.h"

GLfloat kColorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

// yuv to rgb 着色器
NSString *const fragmentShaderString = SHADER_STRING(
// varying highp vec2 textureCoordinate;
//
// uniform sampler2D luminanceTexture;
// uniform sampler2D chrominanceTexture;
// uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
//     mediump vec3 yuv;
//     lowp vec3 rgb;
//
//     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
//     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
//     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);//vec4(rgb, 1);
 }
 );


// 通用着色器
NSString *const vertexShaderString = SHADER_STRING(
 attribute vec4 position;
// attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
//     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

//NSString *const fragmentShaderString = SHADER_STRING(
// varying highp vec2 textureCoordinate;
//
// uniform sampler2D inputImageTexture;
//
// void main()
// {
//     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
// }
//);

/////////////////////////////////////////
@interface FMCameraContext: NSObject

@property (nonatomic, class, readonly) FMCameraContext *shared;
@property (nonatomic) EAGLContext *context;
@property (nonatomic) CVOpenGLESTextureCacheRef textureCache;

@end

@implementation FMCameraContext

+ (FMCameraContext *)shared {
    static FMCameraContext *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

- (EAGLContext *)context {
    if(!_context) {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_context];

        glDisable(GL_DEPTH_TEST);
    }
    return _context;
}

- (CVOpenGLESTextureCacheRef)textureCache {
    if(!_textureCache) {
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, FMCameraContext.shared.context, NULL, &_textureCache);
    }
    return _textureCache;
}

@end

/////////////////////////////////////////


@interface FMCameraOpenGLView() {
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _program;
    GLuint _vertexShader;
    GLuint _fragmentShader;

    GLuint luminanceTexture;
    GLuint chrominanceTexture;
    CVOpenGLESTextureCacheRef textureCache;
    GLint w, h;
}

@end

@implementation FMCameraOpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self setupLayer];
        // 设置当前上下文
        [EAGLContext setCurrentContext:FMCameraContext.shared.context];
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
}

- (void)createProgram {
    _program = glCreateProgram();
    
    _vertexShader = glCreateShader(GL_VERTEX_SHADER);
    const char *vertexSource = [vertexShaderString UTF8String];
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
    const char *fragmentSource = [fragmentShaderString UTF8String];
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
    
    /////
//    glBindAttribLocation(_program, 0, "position");
//    glBindAttribLocation(_program, 1, "inputTextureCoordinate");
    /////
    
    glAttachShader(_program, _vertexShader);
    glAttachShader(_program, _fragmentShader);
    glLinkProgram(_program);
    
    GLint status;
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    
    glDeleteShader(_vertexShader);
    glDeleteShader(_fragmentShader);
}

- (void)renderPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [EAGLContext setCurrentContext:FMCameraContext.shared.context];

    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    // 顶点坐标
    GLfloat vertex[] = {
//        -1.0, -1.0,
        1.0, -1.0,
        -1.0, 1.0,
        1.0, 1.0
    };

    // 纹理坐标
    static const GLfloat textureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
//    [self generateTexture:pixelBuffer];

    [self createProgram];
    
    GLuint positionLoc = glGetAttribLocation(_program, "position");
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, vertex);
    glEnableVertexAttribArray(positionLoc);

//    GLuint textureCoordLoc = glGetAttribLocation(_program, "inputTextureCoordinate");
//    glEnableVertexAttribArray(textureCoordLoc);
//    glVertexAttribPointer(textureCoordLoc, 2, GL_FLOAT, 0, 0, textureCoordinates);

    glUseProgram(_program);

//    glActiveTexture(GL_TEXTURE4);
//    glBindTexture(GL_TEXTURE_2D, luminanceTexture);
//    glUniform1i(glGetUniformLocation(_program, "luminanceTexture"), 4);
//
//    glActiveTexture(GL_TEXTURE5);
//    glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
//    glUniform1i(glGetUniformLocation(_program, "chrominanceTexture"), 5);
//
//    glUniformMatrix3fv(glGetUniformLocation(_program, "colorConversionMatrix"), 1, GL_FALSE, kColorConversion601FullRangeDefault);

//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
//    glBindRenderbuffer(GL_RENDERER, _renderBuffer);
    [FMCameraContext.shared.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)generateTexture:(CVImageBufferRef)videoFrame {
    [EAGLContext setCurrentContext:FMCameraContext.shared.context];

    int bufferWidth = (int)CVPixelBufferGetWidth(videoFrame);
    int bufferHeight = (int)CVPixelBufferGetHeight(videoFrame);
        
    CVOpenGLESTextureRef luminanceTextureRef = NULL;
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;

    // YUV格式
    if(CVPixelBufferGetPlaneCount(videoFrame) > 0) {
        CVPixelBufferLockBaseAddress(videoFrame, 0);

        glActiveTexture(GL_TEXTURE4);
        // 创建亮度纹理 Y-plane
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, FMCameraContext.shared.textureCache, videoFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
        if(err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, luminanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        // 创建色度纹理 UV-plane
        glActiveTexture(GL_TEXTURE5);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, FMCameraContext.shared.textureCache, videoFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);

        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }

        chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        CVPixelBufferUnlockBaseAddress(videoFrame, 0);
        CFRelease(luminanceTextureRef);
        CFRelease(chrominanceTextureRef);
    }

}

//- (void)convertYUVToRGBOutput {
//
//    int rotatedImageBufferWidth = w, rotatedImageBufferHeight = h;
//
//    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//
//    static const GLfloat squareVertices[] = {
//        -1.0f, -1.0f,
//        1.0f, -1.0f,
//        -1.0f,  1.0f,
//        1.0f,  1.0f,
//    };
//
//    glActiveTexture(GL_TEXTURE4);
//    glBindTexture(GL_TEXTURE_2D, luminanceTexture);
//    glUniform1i(yuvConversionLuminanceTextureUniform, 4);
//
//    glActiveTexture(GL_TEXTURE5);
//    glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
//    glUniform1i(yuvConversionChrominanceTextureUniform, 5);
//
//    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);
//
//    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
//    glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [GPUImageFilter textureCoordinatesForRotation:internalRotation]);
//
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//}


@end
