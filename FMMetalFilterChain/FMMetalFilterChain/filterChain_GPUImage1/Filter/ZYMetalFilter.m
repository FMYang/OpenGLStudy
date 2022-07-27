//
//  ZYMetalFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import "ZYMetalFilter.h"
#import "ZYMetalOutputFilter.h"

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
    [self setInputFramebuffer:outputFramebuffer];
    [self newFrameReadyAtTime:frameTime];
}

- (CGSize)sizeOfFBO {
    return CGSizeMake(renderTargetTexture.width, renderTargetTexture.height);
}

#pragma mark - ZYMetalInput

// 子类逐个调用setInputFramebuffer: 和 newFrameReadyAtTime:
- (void)setInputFramebuffer:(ZYMetalFrameBuffer *)newInputFramebuffer {
    renderTargetTexture = newInputFramebuffer.texture;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime {
    outputFramebuffer = [ZYMetalContext.shared.sharedFrameBufferCache fetchFramebufferForSize:[self sizeOfFBO]];

    id<MTLCommandBuffer> commandBuffer = render(renderPipelineState, renderTargetTexture, outputFramebuffer.texture, normalVertices, normalCoordinates);
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    for(id<ZYMetalInput> target in targets) {
        [target setInputFramebuffer:outputFramebuffer];
    }

    // 用完，放回缓存
    [outputFramebuffer unlock];

    for(id<ZYMetalInput> target in targets) {
        [target newFrameReadyAtTime:frameTime];
    }
}

@end
