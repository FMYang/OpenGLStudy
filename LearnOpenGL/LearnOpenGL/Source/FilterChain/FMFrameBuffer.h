//
//  FMFrameBuffer.h
//  LearnOpenGL
//
//  Created by yfm on 2021/9/20.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMFrameBuffer : NSObject

@property(readonly) GLuint texture;

- (id)initWithSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture;

- (void)activateFramebuffer;

- (CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
