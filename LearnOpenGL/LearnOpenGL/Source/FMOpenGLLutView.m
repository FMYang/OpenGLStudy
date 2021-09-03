//
//  FMOpenGLLutView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/3.
//

#import "FMOpenGLLutView.h"

NSString *const lutVertexShaderSource = SHADER_STRING(
    attribute vec4 position;
    attribute vec2 a_texCoordIn;
    varying vec2 v_TexCoordOut;

    void main(void) {
      v_TexCoordOut = a_texCoordIn;
      gl_Position = position;
    }
);

NSString *const lutFragmentShaderSource = SHADER_STRING(
    precision mediump float;

    varying vec2 v_TexCoordOut;
    uniform sampler2D inputImageTexture;
    uniform sampler2D inputImageTexture2; // lookup texture

    void main()
    {
        vec4 textureColor = texture2D(inputImageTexture, v_TexCoordOut);
        
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
        
        vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
        vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
        
        vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
        gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), 0.2);
    }
);

@implementation FMOpenGLLutView {
    NSString *lutImageName;
    GLuint scrTexture;
    GLuint lutTexture;
    
    BOOL needRender;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        lutImageName = @"L01";
    }
    return self;
}

- (void)render {
    // 顶点位置
    const GLfloat vertices[] = {
        -1.0, -1.0, 0.0,   //左下
        1.0,  -1.0, 0.0,   //右下
        -1.0, 1.0,  0.0,   //左上
        1.0,  1.0,  0.0};  //右上
    
    // 纹理坐标
    static const GLfloat coords[] = {
        0, 0,
        1, 0,
        0, 1,
        1, 1
    };
    
    [self createProgramWithVertexShader:lutVertexShaderSource fragmentShader:lutFragmentShaderSource];
    glUseProgram(self.program);
    
    glEnableVertexAttribArray(glGetAttribLocation(self.program, "position"));
    glVertexAttribPointer(glGetAttribLocation(self.program, "position"), 3, GL_FLOAT, GL_FALSE, 0, vertices);
    
    glVertexAttribPointer(glGetAttribLocation(self.program, "a_texCoordIn"), 2, GL_FLOAT, GL_FALSE, 0, coords);
    glEnableVertexAttribArray(glGetAttribLocation(self.program, "a_texCoordIn"));
    
    // 原始图片纹理
    glActiveTexture(GL_TEXTURE0);
    UIImage *srcImage = [UIImage imageNamed:@"2.JPG"];
    scrTexture = [self genTextureFromImage:srcImage];
    glBindTexture(GL_TEXTURE_2D, scrTexture);
    // 指向编号为0的纹理
    glUniform1i(glGetUniformLocation(self.program, "inputImageTexture"), 0);
    
    // lut图片纹理
    glActiveTexture(GL_TEXTURE1);
    UIImage *lutImage = [UIImage imageNamed:lutImageName];
    lutTexture = [self genTextureFromImage:lutImage];
    glBindTexture(GL_TEXTURE_2D, lutTexture);
    // 指向编号为1的纹理
    glUniform1i(glGetUniformLocation(self.program, "inputImageTexture2"), 1);
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)genTextureFromImage:(UIImage *)image {
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
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);

    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, imageRef);
    
    glEnable(GL_TEXTURE_2D);
    
    GLuint texureName;
    glGenTextures(1, &texureName);
    glBindTexture(GL_TEXTURE_2D, texureName);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    glBindTexture(GL_TEXTURE_2D, 0); //解绑
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    free(textureData);
    return texureName;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    lutImageName = [NSString stringWithFormat:@"L0%d", arc4random()%5];
    
    [self clear];
    [self render];
}

- (void)clear {
    if(self.program) {
        glDeleteProgram(self.program);
        self.program = 0;
    }
    
    if(scrTexture) {
        glDeleteTextures(1, &scrTexture);
        scrTexture = 0;
    }
    
    if(lutTexture) {
        glDeleteTextures(1, &lutTexture);
        lutTexture = 0;
    }
}

@end
