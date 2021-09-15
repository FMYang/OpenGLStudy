//
//  FMOpenGLShader330.m
//  LearnOpenGL
//
//  Created by yfm on 2021/8/25.
//

#import "FMOpenGLShaderFinal.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// 包含位置和颜色信息的顶点着色器程序
NSString *const shaderVertexShaderSource = SHADER_STRING(
    attribute vec4 aPos;   // 位置变量的属性位置值为 0
    attribute vec3 aColor; // 颜色变量的属性位置值为 1

    varying vec4 FragColor; // 向片段着色器输出一个颜色

    void main()
    {
        gl_Position = aPos;
        FragColor = vec4(aColor, 1.0); // 将FragColor设置为我们从顶点数据那里得到的输入颜色
    }
);

// 片段着色器（in out 分别使用attribute varying）
NSString *const shaderFragmentShaderSource = SHADER_STRING(
    precision mediump float;
    varying vec4 FragColor;

    void main()
    {
        gl_FragColor = FragColor;
    }
);

@interface FMOpenGLShaderFinal() {
    // 顶点缓冲对象
    GLuint VBO;
    // 索引缓冲对象
    GLuint EBO;
}

@end

@implementation FMOpenGLShaderFinal

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        [self render4];
    }
    return self;
}

// 4、清屏并显示
- (void)render {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中
    glClear(GL_COLOR_BUFFER_BIT);
        
    // 顶点数据
    float vertices[] = {
        0.0f, 0.5f, 0.0f,
        -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f,
    };
    
    /*
     图形渲染管线的第一阶段，顶点着色器。它会在GPU上创建内存用于存储我们的顶点数据
     
     我们通过顶点缓冲对象（Vertex Buffer Objects，VBO）管理这个内存，它会在GPU中存储大量顶点。使用这个对象的好处是我们可以一次性的发送一大批数据到显卡上，而不是每个顶点发送一次。从CPU把数据发送到GPU比较慢，所以尽可能一次性发送尽可能多的数据。
     */
    
    // 创建顶点缓冲对象
    glGenBuffers(1, &VBO);
    // 顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上，复制顶点数组供OpenGL使用
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 把用户定义的数据复制到顶点缓冲中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // 设置顶点属性指针，告诉OpenGL该如何解析顶点数据（应用到逐个顶点属性上）了
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
    // 启用顶点属性
    glEnableVertexAttribArray(0);
        
    [self createProgramWithVertexShader:shaderVertexShaderSource fragmentShader:shaderFragmentShaderSource];
    glUseProgram(self.program);

    // 链接程序后设置颜色才生效
    float greenValue = arc4random() % 10 * 1.0 / 10;
    // 获取ourColor的位置，如果返回-1表示没有找到
    int vertexColorLocation = glGetUniformLocation(self.program, "ourColor");
    // 设置ourColor的值
    glUniform4f(vertexColorLocation, 0.0, greenValue, 0.0, 1.0);
            
    // 绘制三角形
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)render2 {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中
    glClear(GL_COLOR_BUFFER_BIT);
    
    //  设置视口，将屏幕坐标变为标准化设备坐标（范围-1 ～ 1）
    CGFloat scale = UIScreen.mainScreen.scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height  * scale);
    
    // 顶点数据
    float vertices[] = {
        0.5f, 0.5f, 0.0f,   // 右上角
        0.5f, -0.5f, 0.0f,  // 右下角
        -0.5f, -0.5f, 0.0f, // 左下角
        -0.5f, 0.5f, 0.0f   // 左上角
    };

    unsigned int indices[] = { // 注意索引从0开始!
        0, 1, 3, // 第一个三角形
        1, 2, 3  // 第二个三角形
    };
        
    // 创建顶点缓冲对象
    glGenBuffers(1, &VBO);
    // 顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上，复制顶点数组供OpenGL使用
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 把用户定义的数据复制到顶点缓冲中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // VAO是OpenGL 3.0的特性，2.0无法使用这个特效
    /*
     创建顶点数组对象
     
     可以像顶点缓冲对象那样被绑定，任何随后的顶点属性调用都会储存在这个VAO中。这样的好处就是，当配置顶点属性指针时，你只需要将那些调用执行一次，之后再绘制物体的时候只需要绑定相应的VAO就行了。这使在不同顶点数据和属性配置之间切换变得非常简单，只需要绑定不同的VAO就行了。刚刚设置的所有状态都将存储在VAO中
     */
    GLuint VAO;
    glGenVertexArraysOES(1, &VAO);
    glBindVertexArrayOES(VAO);

    // 索引对象，可以减少绘制的顶点数量
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // 设置顶点属性指针，告诉OpenGL该如何解析顶点数据（应用到逐个顶点属性上）了
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GL_FLOAT), (void *)0);
    // 启用顶点属性
    glEnableVertexAttribArray(0);
        
    [self createProgramWithVertexShader:shaderVertexShaderSource fragmentShader:shaderFragmentShaderSource];
    glUseProgram(self.program);

    // 链接程序后设置颜色才生效
    float greenValue = arc4random() % 10 * 1.0 / 10;
    // 获取ourColor的位置，如果返回-1表示没有找到
    int vertexColorLocation = glGetUniformLocation(self.program, "ourColor");
    // 设置uniform类型的ourColor的值
    glUniform4f(vertexColorLocation, 0.0, greenValue, 0.0, 1.0);
    glBindVertexArrayOES(VAO);
    // 索引绘制
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    
    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)render3 {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 顶点数据
    float vertices[] = {
        // 位置              // 颜色
         0.5f, -0.5f, 0.0f,  1.0f, 0.0f, 0.0f,   // 右下
        -0.5f, -0.5f, 0.0f,  0.0f, 1.0f, 0.0f,   // 左下
         0.0f,  0.5f, 0.0f,  0.0f, 0.0f, 1.0f    // 顶部
    };
    
    // 创建顶点缓冲对象
    glGenBuffers(1, &VBO);
    // 顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上，复制顶点数组供OpenGL使用
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 把用户定义的数据复制到顶点缓冲中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint VAO;
    glGenVertexArraysOES(1, &VAO);
    glBindVertexArrayOES(VAO);
    
    // 位置属性
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GL_FLOAT), (void*)0);
    glEnableVertexAttribArray(0);
    // 颜色属性
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GL_FLOAT), (void*)(3* sizeof(GL_FLOAT)));
    glEnableVertexAttribArray(1);
        
    [self createProgramWithVertexShader:shaderVertexShaderSource fragmentShader:shaderFragmentShaderSource];
    glUseProgram(self.program);
    glBindVertexArrayOES(VAO);
    // 索引绘制
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];

}

- (void)render4 {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    // 清除帧缓存附加的渲染缓存信息，下一次绘制不需要上一次的内容，清除以避免将先前的内容加载到内存中
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 顶点数据
    float vertices[] = {
        // 位置              // 颜色
        -1.0,  1.0, 0.0,  1.0, 0.0, 0.0,   // a
        -1.0, -1.0, 0.0,  1.0, 0.0, 0.0,   // b
         1.0, -1.0, 0.0,  1.0, 0.0, 0.0,   // c
        
        -1.0, 1.0, 0.0,   0.0, 1.0, 0.0,   // b
         1.0, -1.0, 0.0,  0.0, 1.0, 0.0,   // c
         1.0,  1.0, 0.0,  0.0, 1.0, 0.0    // d
    };
    
    // 创建顶点缓冲对象
    glGenBuffers(1, &VBO);
    // 顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，把新创建的缓冲绑定到GL_ARRAY_BUFFER目标上，复制顶点数组供OpenGL使用
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 把用户定义的数据复制到顶点缓冲中
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    GLuint VAO;
    glGenVertexArraysOES(1, &VAO);
    glBindVertexArrayOES(VAO);
    
    // 位置属性
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GL_FLOAT), (void*)0);
    glEnableVertexAttribArray(0);
    // 颜色属性
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GL_FLOAT), (void*)(3* sizeof(GL_FLOAT)));
    glEnableVertexAttribArray(1);
        
    [self createProgramWithVertexShader:shaderVertexShaderSource fragmentShader:shaderFragmentShaderSource];
    glUseProgram(self.program);
    glBindVertexArrayOES(VAO);
    // 索引绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    // 渲染缓存（颜色渲染缓存）保存完成的帧，将渲染缓存绑定到上下文并呈现它。这会将完成的帧交给Core Animation绘制。
    [self.context presentRenderbuffer:GL_RENDERBUFFER];

}

@end
