//
//  ZYMetalFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import "ZYMetalFilter.h"

@interface ZYMetalFilter() {
    id<MTLTexture> renderTargetTexture;
    NSString *fragmentFunction;
    id<MTLRenderPipelineState> renderPipelineState;
}

@end

@implementation ZYMetalFilter

- (id)initWithFragmentFunction:(NSString *)function {
    if(self = [super init]) {
        fragmentFunction = function;
                
        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        renderPipelineDescriptor.vertexFunction = [ZYMetalContext.shared.library newFunctionWithName:@"normalVertex"];
        renderPipelineDescriptor.fragmentFunction = [ZYMetalContext.shared.library newFunctionWithName:fragmentFunction];

        renderPipelineState = [ZYMetalContext.shared.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:nil];
    }
    return self;
}

// 将相机输出帧，写入全局缓存的离屏纹理（outputFramebuffer）
- (void)push:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime {
    CVMetalTextureRef cameraTexture = nil;
    CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, ZYMetalContext.shared.textureCache, pixelBuffer, nil, MTLPixelFormatBGRA8Unorm, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 0, &cameraTexture);
    CGSize size = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    outputFramebuffer = [ZYMetalContext.shared.sharedFrameBufferCache fetchFramebufferForSize:size];

    id<MTLCommandBuffer> commandBuffer = render(ZYMetalContext.shared.normalRenderPipelineState, outputFramebuffer.texture, CVMetalTextureGetTexture(cameraTexture), normalVertices, normalCoordinates);
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    [outputFramebuffer unlock];
    
    CFRelease(cameraTexture);
    
    // 开始滤镜链调用
    [self setInputFramebuffer:outputFramebuffer atIndex:0];
    [self newFrameReadyAtTime:frameTime atIndex:0];
}

- (CGSize)sizeOfFBO {
    return CGSizeMake(renderTargetTexture.width, renderTargetTexture.height);
}

#pragma mark - ZYMetalInput

// 子类逐个调用setInputFramebuffer: 和 newFrameReadyAtTime:
- (void)setInputFramebuffer:(ZYMetalFrameBuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    renderTargetTexture = newInputFramebuffer.texture;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    // 写和显示是两块缓存，不能只取显示的缓存，这里要区分（怎么区分，缓存机制还不完善）
    outputFramebuffer = [ZYMetalContext.shared.sharedFrameBufferCache fetchFramebufferForSize:[self sizeOfFBO]];
    NSLog(@"%@", outputFramebuffer);
    id<MTLCommandBuffer> commandBuffer = render(renderPipelineState, renderTargetTexture, outputFramebuffer.texture, normalVertices, normalCoordinates);
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    [outputFramebuffer unlock];

    for(id<ZYMetalInput> target in targets) {
        [target setInputFramebuffer:outputFramebuffer atIndex:0];
        [target newFrameReadyAtTime:frameTime atIndex:0];
    }
}

@end
