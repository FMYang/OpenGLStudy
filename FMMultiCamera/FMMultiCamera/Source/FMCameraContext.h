//
//  FMCameraContext.h
//  LearnOpenGL
//
//  Created by yfm on 2021/9/18.
//

/**
 
 iOS 应用程序中的每个线程都有一个当前上下文；当您调用 OpenGL ES 函数时，这是其状态被调用更改的上下文。

 要设置线程的当前上下文，请在该线程上执行时调用EAGLContext类方法setCurrentContext:
 
 注意： 如果您的应用程序在同一线程上的两个或多个上下文之间主动切换，请glFlush在将新上下文设置为当前上下文之前调用该函数。这可确保将先前提交的命令及时传送到图形硬件。

 
 注意： 另一种共享对象的方法是使用单个渲染上下文，但使用多个目标帧缓冲区。在渲染时，您的应用会绑定适当的帧缓冲区并根据需要渲染其帧。因为所有 OpenGL ES 对象都是从单个上下文引用的，所以它们看到相同的 OpenGL ES 数据。此模式使用较少的资源，但仅适用于您可以仔细控制上下文状态的单线程应用程序。

 */

#import <Foundation/Foundation.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGLDrawable.h>

#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMCameraContext : NSObject

// 当前使用的上下文，相机输出回调中，表示当前线程激活的上下文（重要：上下文不一致的话什么都画不出来）
@property(readonly, retain, nonatomic) EAGLContext *context;
// 上下文队列
@property(readonly, nonatomic) dispatch_queue_t contextQueue;
// 纹理缓存对象
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;

+ (FMCameraContext *)shared;
+ (void)useImageProcessingContext;

- (void)presentBufferForDisplay;

@end

NS_ASSUME_NONNULL_END
