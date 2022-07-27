//
//  ZYMetalOutputFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/26.
//

#import "ZYMetalOutputFilter.h"

@interface ZYMetalOutputFilter() {
    id<MTLTexture> renderTargetTexture;
}
@end

@implementation ZYMetalOutputFilter

- (CGSize)sizeOfFBO {
    return CGSizeMake(renderTargetTexture.width, renderTargetTexture.height);
}

- (void)setInputFramebuffer:(ZYMetalFrameBuffer *)newInputFramebuffer {
    renderTargetTexture = newInputFramebuffer.texture;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime {
    if(!outputFramebuffer) {
        outputFramebuffer = [ZYMetalContext.shared.sharedFrameBufferCache fetchFramebufferForSize:[self sizeOfFBO]];
    }
    
    id<MTLCommandBuffer> commandBuffer = render(ZYMetalContext.shared.normalRenderPipelineState, outputFramebuffer.texture, renderTargetTexture, normalVertices, normalCoordinates);
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

@end
