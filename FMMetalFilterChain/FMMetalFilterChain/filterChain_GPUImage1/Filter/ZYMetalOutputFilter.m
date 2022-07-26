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

- (void)setInputFramebuffer:(ZYMetalFrameBuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    renderTargetTexture = newInputFramebuffer.texture;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    if(!_metalOutputFrameBuffer) {
        NSLog(@"fm ~~~~~~~~~");
        _metalOutputFrameBuffer = [[ZYMetalFrameBuffer alloc] initWithSize:[self sizeOfFBO]];
    }
    
    id<MTLCommandBuffer> commandBuffer = render(ZYMetalContext.shared.normalRenderPipelineState, _metalOutputFrameBuffer.texture, renderTargetTexture, normalVertices, normalCoordinates);
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

@end
