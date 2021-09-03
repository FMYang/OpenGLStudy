//
//  FMOpenGLView.m
//  RosyWriterOpenGL
//
//  Created by yfm on 2021/9/3.
//

#import "FMOpenGLView.h"
#import <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#if !defined(_STRINGIFY)
#define __STRINGIFY( _x )   # _x
#define _STRINGIFY( _x ) @ __STRINGIFY( _x )
#endif

// 顶点着色器
NSString *const textureVertexShaderSource = _STRINGIFY(
    attribute vec4 position;
    attribute mediump vec4 texturecoordinate;
    varying mediump vec2 coordinate;

    void main()
    {
        gl_Position = position;
        coordinate = texturecoordinate.xy;
    }
);

// 片段着色器
NSString *const textureFragmentShaderSource = _STRINGIFY(
    precision mediump float; // 加上这个
    varying highp vec2 coordinate;
    uniform sampler2D videoframe;

    void main()
    {
        gl_FragColor = texture2D(videoframe, coordinate);
//    gl_FragColor = vec4(vec3(1.0 - texture2D(videoframe, coordinate)), 1.0);
    
    // 更精确的灰度，人眼对绿色更加敏感些，对蓝色不那么敏感
//        float average = (gl_FragColor.r + gl_FragColor.g + gl_FragColor.b) / 3.0;
////        float average = 0.2126 * gl_FragColor.r + 0.7152 * gl_FragColor.g + 0.0722 * gl_FragColor.b;
//        gl_FragColor = vec4(average, average, average, 1.0);
    }
);


@interface FMOpenGLView() {
    // 顶点着色器
    GLuint _vertextShader;
    // 片段着色器
    GLuint _fragmentShader;
    
    GLuint positionLoc;
    GLuint texturecoordinateLoc;
    GLuint videoframeLoc;
    
    GLint _width;
    GLint _height;
}

// openGL上下文，管理OpenGL状态，openGL是一个大的状态机
@property (nonatomic) EAGLContext *context;
// 图层layer
@property (nonatomic) CAEAGLLayer *eagLayer;
// 渲染缓存（包括颜色缓存、深度测试）ID
@property (nonatomic) GLuint renderBuffer;
// 帧缓存ID（帧缓冲区对象是渲染命令的目的地。帧缓存可以附加渲染缓存）
@property (nonatomic) GLuint frameBuffer;
// 着色器程序对象
@property (nonatomic) GLuint program;
// 纹理缓存
@property (nonatomic) CVOpenGLESTextureCacheRef textureCache;

@end

@implementation FMOpenGLView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)init {
    if(self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setupLayer];
    [self createContext];
}

- (void)initializeBuffers {
    [self createRenderAndFrameBuffer];
    [self loadProgram];
}

- (void)setupLayer {
    self.eagLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:UIScreen.mainScreen.scale];
    self.eagLayer.opaque = YES;
    self.eagLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @(FALSE),
                                        kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
}

- (void)createContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(![EAGLContext setCurrentContext:context]) {
        NSLog(@"设置上下文失败");
    }
    self.context = context;
}

- (void)createRenderAndFrameBuffer {
    // 创建渲染缓存对象
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    // 为图层对象分配存储空间。宽度、高度和像素格式取自layer，用于为渲染缓存分配存储空间。
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eagLayer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_height);
        
    // 创建帧缓存
    glGenRenderbuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // 将渲染缓存附加到帧缓存
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);

}

- (void)loadProgram {
    CVReturn err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, self.context, NULL, &_textureCache );
    if ( err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreate %d", err );
    }

    const GLchar *vertexSource = (GLchar *)[textureVertexShaderSource UTF8String];
    const GLchar *fragmentSource = (GLchar *)[textureFragmentShaderSource UTF8String];

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
    
    // Bind attribute locations
    // This needs to be done prior to linking
    glBindAttribLocation(_program, 0, "postion");
    glBindAttribLocation(_program, 1, "texturecoordinate");
    
    glLinkProgram(_program);

    positionLoc = glGetAttribLocation(_program, "position");
    texturecoordinateLoc = glGetAttribLocation(_program, "texturecoordinate");
        
    
    glDeleteShader(_vertextShader);
    glDeleteShader(_fragmentShader);
    
    videoframeLoc = glGetUniformLocation(_program, "videoFrame");
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f, // bottom left
        1.0f, -1.0f, // bottom right
        -1.0f,  1.0f, // top left
        1.0f,  1.0f, // top right
    };
    
    if(pixelBuffer == NULL) return;
    
    if(_frameBuffer == 0) {
        [self initializeBuffers];
    }
    
    // 创建纹理
    size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    CVOpenGLESTextureRef texture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                _textureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                (GLsizei)frameWidth,
                                                                (GLsizei)frameHeight,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &texture);    

    if(!texture || err) {
        return;
    }
    
    glViewport(0, 0, _width, _height);
    glUseProgram(_program);
        
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(CVOpenGLESTextureGetTarget(texture), CVOpenGLESTextureGetName(texture));

    glUniform1i(videoframeLoc, 0);

    // Set texture parameters
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, squareVertices );
    glEnableVertexAttribArray(positionLoc);
    
    // 坐标转换
    CGSize textureSamplingSize;
    CGSize cropScaleAmount = CGSizeMake( self.bounds.size.width / (float)frameWidth, self.bounds.size.height / (float)frameHeight );
    if ( cropScaleAmount.height > cropScaleAmount.width ) {
        textureSamplingSize.width = self.bounds.size.width / ( frameWidth * cropScaleAmount.height );
        textureSamplingSize.height = 1.0;
    }
    else {
        textureSamplingSize.width = 1.0;
        textureSamplingSize.height = self.bounds.size.height / ( frameHeight * cropScaleAmount.width );
    }
    
    GLfloat passThroughTextureVertices[] = {
        ( 1.0 - textureSamplingSize.width ) / 2.0, ( 1.0 + textureSamplingSize.height ) / 2.0, // top left
        ( 1.0 + textureSamplingSize.width ) / 2.0, ( 1.0 + textureSamplingSize.height ) / 2.0, // top right
        ( 1.0 - textureSamplingSize.width ) / 2.0, ( 1.0 - textureSamplingSize.height ) / 2.0, // bottom left
        ( 1.0 + textureSamplingSize.width ) / 2.0, ( 1.0 - textureSamplingSize.height ) / 2.0, // bottom right
    };
    
    glVertexAttribPointer(texturecoordinateLoc, 2, GL_FLOAT, 0, 0, passThroughTextureVertices);
    glEnableVertexAttribArray(texturecoordinateLoc);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    glBindTexture(CVOpenGLESTextureGetTarget(texture), 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    CFRelease(texture);
}

- (void)flushPixelBufferCache {
    if(_textureCache) {
        CVOpenGLESTextureCacheFlush(_textureCache, 0);
    }
}

- (void)dealloc {
    [self reset];
}

- (void)reset {
    EAGLContext *oldContext = [EAGLContext currentContext];
    if ( oldContext != self.context ) {
        if ( ! [EAGLContext setCurrentContext:self.context] ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
            return;
        }
    }
    if ( _frameBuffer ) {
        glDeleteFramebuffers( 1, &_frameBuffer );
        _frameBuffer = 0;
    }
    if ( _renderBuffer ) {
        glDeleteRenderbuffers( 1, &_renderBuffer );
        _renderBuffer = 0;
    }
    if ( _program ) {
        glDeleteProgram( _program );
        _program = 0;
    }
    if ( _textureCache ) {
        CFRelease( _textureCache );
        _textureCache = 0;
    }
    if ( oldContext != self.context ) {
        [EAGLContext setCurrentContext:oldContext];
    }
}


@end
