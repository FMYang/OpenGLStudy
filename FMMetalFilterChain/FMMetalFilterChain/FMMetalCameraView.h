//
//  FMMetalCameraView.h
//  LearnMetal
//
//  Created by yfm on 2021/10/17.
//

#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FMMetalCameraView : MTKView

- (void)renderPixelBuffer:(id<MTLTexture>)inputTexture;

@end

NS_ASSUME_NONNULL_END
