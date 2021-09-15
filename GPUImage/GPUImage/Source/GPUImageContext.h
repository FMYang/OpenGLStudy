//
//  GPUImageContext.h
//  GPUImage
//
//  Created by yfm on 2021/9/14.
//

#import "GLProgram.h"
#import "GPUImageFramebuffer.h"
#import "GPUImageFramebufferCache.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, GPUImageRotationMode) {
    kGPUImageNoRotation,
    kGPUImageRotateLeft,
    kGPUImageRotateRight,
    kGPUImageFlipVertical,
    kGPUImageFlipHorizonal,
    kGPUImageRotateRightFlipVertical,
    kGPUImageRotateRightFlipHorizontal,
    kGPUImageRotate180
};

@interface GPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readwrite, retain, nonatomic) GLProgram *currentShaderProgram;
@property(readonly, retain, nonatomic) EAGLContext *context;
// 纹理缓存对象
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
// 帧缓存对象管理对象
@property(readonly) GPUImageFramebufferCache *framebufferCache;

+ (void *)contextKey;
// 共享图片处理上下文
+ (GPUImageContext *)sharedImageProcessingContext;
// 上下文队列
+ (dispatch_queue_t)sharedContextQueue;
// 纹理对象管理对象
+ (GPUImageFramebufferCache *)sharedFramebufferCache;
// 图片处理上下文
+ (void)useImageProcessingContext;
+ (void)setActiveShaderProgram:(GLProgram *)shaderProgram;

- (void)presentBufferForDisplay;
- (GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

+ (BOOL)supportsFastTextureUpload;

@end

// input协议
@protocol GPUImageInput <NSObject>
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
- (NSInteger)nextAvailableTextureIndex;
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
- (CGSize)maximumOutputSize;
- (void)endProcessing;
- (BOOL)shouldIgnoreUpdatesToThisTarget;
- (BOOL)enabled;
- (BOOL)wantsMonochromeInput;
- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
@end

NS_ASSUME_NONNULL_END
