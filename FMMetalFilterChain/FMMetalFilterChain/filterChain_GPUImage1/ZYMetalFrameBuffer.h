//
//  ZYMetalFrameBuffer.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/19.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZYMetalFrameBuffer : NSObject

@property(readonly) CGSize size;
@property(readonly) id<MTLTexture> texture;

- (CVPixelBufferRef)pixelBuffer;
- (id)initWithSize:(CGSize)framebufferSize;

@end

NS_ASSUME_NONNULL_END
