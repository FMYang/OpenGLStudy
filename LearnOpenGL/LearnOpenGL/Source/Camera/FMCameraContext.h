//
//  FMCameraContext.h
//  LearnOpenGL
//
//  Created by yfm on 2021/9/18.
//

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
