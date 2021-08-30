//
//  ViewController.m
//  OpenGL_ES_Lession1
//
//  Created by yfm on 2021/6/2.
//

#import "ViewController.h"

// 顶点结构体，用于存储每个顶点的信息
typedef struct {
    GLKVector3 positionCoords;
} SceneVertex;

// 用顶点数据初始化的普通C数组，定义三角形
static const SceneVertex vertices[] = {
    {{-0.5f, -0.5f, 0.0}}, // lower left corner  左下角
    {{ 0.5f, -0.5f, 0.0}}, // lower right corner 右下角
    {{-0.5f,  0.5f, 0.0}}  // upper left corner  左上角
};

@interface ViewController ()

@end

@implementation ViewController

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GLKView *view = (GLKView *)self.view;
    NSAssert([view isKindOfClass:[GLKView class]], @"View controller's view is not a GLKView");

    // 创建OpenGL上下文，提供给GLKView
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    // 使新的上下文成为当前上下文
    [EAGLContext setCurrentContext:view.context];
    
    // GLKBaseEffect提供标准的OpenGL ES 2.0的作色器语言程序（Shading Language programs）,
    // 设置后续渲染需要用到的参数
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);

    // 设置存储在当前上下文中的背景颜色
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f); // 背景色

    // 生成、绑定、初始化存储在GPU内存中的缓冲区内容
    // 1.生成缓冲区，为缓存生成一个独一无二的标识符
    // 第一个参数用于指定要生成的缓存标识符的梳理，第二个参数表示指向标识在内存中的指针
    glGenBuffers(1, &vertexbufferID);
    // 2.通过标识符绑定缓冲区，为接下来的运算绑定缓存
    // 第一个参数是一个常量，用于指定要绑定哪一种类型的缓存；第二个参数表示缓存的标识符
    glBindBuffer(GL_ARRAY_BUFFER, vertexbufferID);
    // 3.复制数据到缓存中
    // GL_STATIC_DRAW会告诉上下文，缓存的内容适合复制到GPU控制的内存，因为很少对其进行更改
    // GL_DYNAMIC_DRAW会告诉上下文，缓存的内容会频繁改变，提示OpenGL ES以不同的方式来处理缓存的存储
    glBufferData(GL_ARRAY_BUFFER,  // 初始化缓冲区内容
                 sizeof(vertices), // 要拷贝进这个缓存的字节数
                 vertices,         // 要拷贝的字节地址
                 GL_STATIC_DRAW);  // 提示：缓存在GPU内存中
}

/**
 GLKView 委托方法：由视图控制器的视图调用每当 Cocoa Touch 要求视图控制器的视图绘制自身。
 （在这种情况下，渲染到一个帧缓冲区与核心动画层共享内存）
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.baseEffect prepareToDraw];

    // 清除帧缓冲区（擦除之前的绘图）
    glClear(GL_COLOR_BUFFER_BIT);

    // 允许使用来自绑定顶点缓冲区的位置
    // 4.启动顶点缓存渲染操作
    glEnableVertexAttribArray(GLKVertexAttribPosition);

    // 5.告诉OpenGL ES顶点数据在哪里，以及怎么解释为每个顶点保存的数据
    glVertexAttribPointer(GLKVertexAttribPosition,  // 指示当前绑定的缓存包含每个顶点的位置信息
                          3,                        // 每个位置有3个部分
                          GL_FLOAT,                 // 告诉OpenGL ES每个部分都保存为浮点类型的值
                          GL_FALSE,                 // 告诉OpenGL ES小数点固定数据是否可以被改变
                          sizeof(SceneVertex),      // “步幅”：指定了每个顶点的保存需要多少个字节
                          NULL);                    // NULL告诉GPU从当前绑定的缓存的开始位置访问顶点数据

    // 在当前绑定的顶点缓冲区中，使用前三个点绘制三角形
    glDrawArrays(GL_TRIANGLES, // 告诉GPU怎么处理在绑定的顶点缓存内的顶点数据，GL_TRIANGLES指示OpenGL ES去渲染三角形
                 0,  // 需要渲染的第一个顶点的位置
                 3); // 需要渲染的顶点的数量
}

- (void)dealloc {
    GLKView *view=  (GLKView *)self.view;
    [EAGLContext setCurrentContext:view.context];
    
    if(0 != vertexbufferID) {
        glDeleteBuffers(1, &vertexbufferID);
        vertexbufferID = 0;
    }
    
    ((GLKView *)self.view).context = nil;
    [EAGLContext setCurrentContext:nil];
}

@end
