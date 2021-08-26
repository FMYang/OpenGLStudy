//
//  FMOpenGLTexture.m
//  LearnOpenGL
//
//  Created by yfm on 2021/8/26.
//

#import "FMOpenGLTexture.h"

// 顶点着色器
NSString *const textureVertexShaderSource = SHADER_STRING(
    precision mediump float;
    attribute vec3 aPos;
    attribute vec3 aColor;
    attribute vec2 aTexCoord;

    varying vec3 outColor;
    varying vec2 TexCoord;
                                                          
    void main()
    {
       gl_Position = vec4(aPos, 1.0);
    
       outColor = aColor;
       TexCoord = aTexCoord;
    }
);

// 片段着色器
NSString *const textureFragmentShaderSource = SHADER_STRING(
    precision mediump float;
    varying vec3 ourColor;
    varying vec2 TexCoord;

    uniform sampler2D ourTexture;

    void main()
    {
        gl_FragColor = texture2D(ourTexture, TexCoord);
    }
);

@interface FMOpenGLTexture()

// 顶点缓冲对象
@property (nonatomic) GLuint VBO;
// 索引缓冲对象
@property (nonatomic) GLuint EBO;

// 纹理对象
@property (nonatomic) GLuint texture;

@end

@implementation FMOpenGLTexture

- (void)render {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    float vertices[] = {
        // ---- 位置 ----       ---- 颜色 ----     - 纹理坐标 -
        1.0f,  1.0f, 0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   // 右上
        1.0f, -1.0f, 0.0f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f,   // 右下
        -1.0f, -1.0f, 0.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   // 左下

        -1.0f,  1.0f, 0.0f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f,    // 左上
        1.0f,  1.0f, 0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   // 右上
        -1.0f, -1.0f, 0.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   // 左下
    };

    glGenBuffers(1, &_VBO);
    glBindBuffer(GL_ARRAY_BUFFER, _VBO);
    // 顶点数据从CPU复制到GPU中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    [self createProgramWithVertexShader:textureVertexShaderSource fragmentShader:textureFragmentShaderSource];
    glUseProgram(self.program);
    
    // 顶点
    GLuint positionLocation = glGetAttribLocation(self.program, "aPos");
    glEnableVertexAttribArray(positionLocation);
    glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GL_FLOAT), (void *)0);

    // 颜色
    GLuint colorLocation = glGetAttribLocation(self.program, "aColor");
    glEnableVertexAttribArray(colorLocation);
    glVertexAttribPointer(colorLocation, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (GLfloat *)NULL + 3);
    
    // 纹理坐标
    GLuint texLoc = glGetAttribLocation(self.program, "aTexCoord");
    glEnableVertexAttribArray(texLoc);
    glVertexAttribPointer(texLoc, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GL_FLOAT), (GLfloat *)NULL + 6);

    [self genTexture];
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)genTexture {
    UIImage *img = [UIImage imageNamed:@"1.jpeg"];
    CGImageRef imageRef = img.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    GLubyte *textureData = (GLubyte *)malloc(width * height * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGContextRef context = CGBitmapContextCreate(textureData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // 生成纹理
    GLuint texture;
    glGenTextures(1, &texture);
    // 在绑定纹理之前先激活纹理单元，OpenGL ES中最多可以激活8个通道。通道0是默认激活的，所以本例中这一句也可以不写
    glActiveTexture(texture);
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, texture);
    
    /*
     参数 target ：指定纹理单元的类型，二维纹理需要指定为GL_TEXTURE_2D
     参数 level：指定纹理单元的层次，非mipmap纹理level设置为0，mipmap纹理设置为纹理的层级
     参数 internalFormat：指定OpenGL ES是如何管理纹理单元中数据格式的
     参数 width：指定纹理单元的宽度（必须是2的幂）
     参数 height：指定纹理单元的高度（必须是2的幂）
     参数 border：指定纹理单元的边框，如果包含边框取值为1，不包含边框取值为0
     参数 format：指定data所指向的数据的格式
     参数 type：指定data所指向的数据的类型
     参数 data：实际指向的数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    
    glUniform1i(glGetUniformLocation(self.program, "ourTexture"), 0);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glGenerateMipmap(GL_TEXTURE_2D);
}

@end
