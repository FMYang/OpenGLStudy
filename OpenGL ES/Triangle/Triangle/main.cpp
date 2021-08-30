// Triangle.cpp
// Our first OpenGL program that will just draw a triangle on the screen.

#include <GLTools.h>            // OpenGL toolkit
#include <GLShaderManager.h>    // GLTools着色器管理类，没有着色器，我们就不能在OpenGL中进行着色

#ifdef __APPLE__
#include <glut/glut.h>          // OS X version of GLUT OpenGL工具箱 GLUT
#else
#define FREEGLUT_STATIC
#include <GL/glut.h>            // Windows FreeGlut equivalent
#endif

GLBatch    triangleBatch;
GLShaderManager    shaderManager;

///////////////////////////////////////////////////////////////////////////////
// Window has changed size, or has just been created. In either case, we need
// to use the window dimensions to set the viewport and the projection matrix.
void ChangeSize(int w, int h) {
    glViewport(0, 0, w, h);
}


///////////////////////////////////////////////////////////////////////////////
// This function does any needed initialization on the rendering context.
// This is the first opportunity to do any OpenGL related tasks.
void SetupRC() {
    // Blue background
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f );
    
    // 初始化着色器
    shaderManager.InitializeStockShaders();

    // 三角形顶点
    GLfloat vVerts[] = { -0.5f, 0.0f, 0.0f,
                          0.5f, 0.0f, 0.0f,
                          0.0f, 0.5f, 0.0f };

    triangleBatch.Begin(GL_TRIANGLES, 3);
    triangleBatch.CopyVertexData3f(vVerts);
    triangleBatch.End();
}


///////////////////////////////////////////////////////////////////////////////
// 渲染场景
void RenderScene(void) {
    // Clear the window with current clearing color
    // glClear函数清除一个或一组特定的缓冲区。缓冲区是一块存储图像信息的存储空间。
    // 此例子使用按位或清除颜色缓冲区、深度缓冲区和模版缓冲区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    GLfloat vRed[] = { 1.0f, 0.0f, 0.0f, 1.0f };
    shaderManager.UseStockShader(GLT_SHADER_IDENTITY, vRed);
    triangleBatch.Draw();

    // Perform the buffer swap to display back buffer
    // 设置OpenGL窗口时，我们指定要一个双缓冲区渲染环境。这就意味着在后台缓冲区进行渲染，然后结束时交换到前台。
    // 交换前后缓存区
    glutSwapBuffers();
}


///////////////////////////////////////////////////////////////////////////////
// Main entry point for GLUT based programs
int main(int argc, char* argv[]) {
    // 设置当前的工作目录
    gltSetWorkingDirectory(argv[0]);
    
    // 初始化GLUT库
    glutInit(&argc, argv);
    // 这里的标志告诉它要使用双缓冲窗口（GLUT_DOUBLE）和RGBA颜色模式（GLUT_RGBA）
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_STENCIL);
    // 创建窗口大小
    glutInitWindowSize(400, 300);
    // 窗口标题
    glutCreateWindow("Triangle");
    // 窗口大小改变时的回调函数
    glutReshapeFunc(ChangeSize);
    // 渲染函数
    glutDisplayFunc(RenderScene);

    // 初始化GLEW库。在试图做任何渲染之前，要检查确定驱动程序的初始化过程中没有出现任何问题
    GLenum err = glewInit();
    if (GLEW_OK != err) {
        fprintf(stderr, "GLEW Error: %s\n", glewGetErrorString(err));
        return 1;
    }
    
    SetupRC();

    // 开始消息循环
    glutMainLoop();
    
    return 0;
}
