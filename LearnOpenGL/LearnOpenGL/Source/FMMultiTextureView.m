//
//  FMMultiTextureView.m
//  LearnOpenGL
//
//  Created by yfm on 2021/9/28.
//

#import "FMMultiTextureView.h"

// 顶点着色器
NSString *const multiTextureVertexShaderSource = SHADER_STRING(
    precision mediump float;
    attribute vec2 postion;
    attribute vec2 textureCoord;

    varying vec2 aTextureCoord;
                                                          
    void main()
    {
       gl_Position = vec4(postion, 0.0, 1.0);
    
       aTextureCoord = textureCoord;
    }
);

// 片段着色器
NSString *const multiTextureFragmentShaderSource = SHADER_STRING(
    precision mediump float;
    varying vec2 aTextureCoord;

    uniform sampler2D textureIndex1;
    uniform sampler2D textureIndex2;

    void main()
    {
        if(aTextureCoord.y >= 0.5) {
            gl_FragColor = texture2D(textureIndex1, aTextureCoord);
        } else {
            gl_FragColor = texture2D(textureIndex2, aTextureCoord);
        }
    }
);


@implementation FMMultiTextureView

- (void)render {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    float vertices[] = {
        -1, -1,
         1, -1,
        -1, 0,
         1, 0,
        
        -1, 0,
         1, 0,
        -1, 1,
         1, 1
    };
    
    float textureCoord[] = {
        0, 0,
        1, 0,
        0, 0.5,
        1, 0.5,
        
        0, 0.5,
        1, 0.5,
        0, 1,
        1, 1
    };

    [self createProgramWithVertexShader:multiTextureVertexShaderSource fragmentShader:multiTextureFragmentShaderSource];
    glUseProgram(self.program);
    
    // 顶点
    GLuint positionLocation = glGetAttribLocation(self.program, "postion");
    glVertexAttribPointer(positionLocation, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(positionLocation);

    // 纹理坐标
    GLuint texLoc = glGetAttribLocation(self.program, "textureCoord");
    glEnableVertexAttribArray(texLoc);
    glVertexAttribPointer(texLoc, 2, GL_FLOAT, 0, 0, textureCoord);

    GLuint texture1 = [self genTexture:@"1.jpeg" index:1];
    GLuint texture2 = [self genTexture:@"2.jpeg" index:2];

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texture1);
    glUniform1i(glGetUniformLocation(self.program, "textureIndex1"), 1);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, texture2);
    glUniform1i(glGetUniformLocation(self.program, "textureIndex2"), 2);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 8);
    
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)genTexture:(NSString *)imageName index:(int)index {
    UIImage *img = [UIImage imageNamed:imageName];
    
    CGImageRef imageRef = img.CGImage;
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    // 为textureData分配存储空间，rgba占用4字节，纹理占用的空间大小为图片宽x高x4
    GLubyte *textureData = (GLubyte *)malloc(width * height * 4);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    /*
     根据图片宽高和颜色空间生成位图
     参数1：指向要渲染的绘制内存的地址
     参数2：bitmap的宽度,单位为像素
     参数3：bitmap的高度,单位为像素
     参数4：内存中像素的每个组件的位数.例如，对于32位像素格式和RGB 颜色空间，你应该将这个值设为8.
     参数5：bitmap的每一行在内存所占的字节数
     参数6：指定bitmap是否包含alpha通道，像素中alpha通道的相对位置，像素组件是整形还是浮点型等信息的字符串。
    */
    CGContextRef context = CGBitmapContextCreate(textureData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);
    
    // 翻转Core Graphics Y轴
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // 将图片数据转为RGB数据存储在变量textureData中
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // 生成纹理
    GLuint texture;
    glGenTextures(1, &texture);
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
    
    // 给片段着色器的ourTexture变量赋值，默认使用第0块纹理，这里传0
    glUniform1i(glGetUniformLocation(self.program, "ourTexture"), 0);
    
    // 设置环绕方式
    /**
     GL_REPEAT    对纹理的默认行为。重复纹理图像。
     GL_MIRRORED_REPEAT    和GL_REPEAT一样，但每次重复图片是镜像放置的。
     GL_CLAMP_TO_EDGE    纹理坐标会被约束在0到1之间，超出的部分会重复纹理坐标的边缘，产生一种边缘被拉伸的效果。
     GL_CLAMP_TO_BORDER    超出的坐标为用户指定的边缘颜色。
     */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // mip贴图
    glGenerateMipmap(GL_TEXTURE_2D);
    
    // 释放纹理数据
    free(textureData);
    
    return texture;
}


@end
