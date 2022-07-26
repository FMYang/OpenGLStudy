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
@property(nonatomic) NSInteger index;

- (id)initWithSize:(CGSize)framebufferSize;

- (CVPixelBufferRef)pixelBuffer;

- (void)lock;
- (void)unlock;

@end

NS_ASSUME_NONNULL_END
