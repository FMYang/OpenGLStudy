//
//  FMFrameBuffer.h
//  FMMultiCamera
//
//  Created by yfm on 2021/9/29.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMFrameBuffer : NSObject

- (instancetype)initWithSize:(CGSize)frameBufferSize;
- (CVPixelBufferRef)pixelBuffer;
- (GLuint)texture;
- (void)activateFramebuffer;
@end

NS_ASSUME_NONNULL_END
