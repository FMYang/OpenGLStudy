//
//  CustomRenderer.h
//  LearnMetal
//
//  Created by yfm on 2022/7/8.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomRenderer : NSObject

- (nonnull instancetype)initWithMetalDevice:(nonnull id<MTLDevice>)device
                        drawablePixelFormat:(MTLPixelFormat)drawablePixelFormat;

- (void)renderToMetalLayer:(nonnull CAMetalLayer *)metalLayer;

- (void)drawableResize:(CGSize)drawableSize;

@end

NS_ASSUME_NONNULL_END
