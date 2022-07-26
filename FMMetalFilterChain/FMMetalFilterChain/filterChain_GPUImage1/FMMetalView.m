//
//  FMMetalView.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#import "FMMetalView.h"

@interface FMMetalView() {
    id<MTLTexture> renderTexture;
}
@end

@implementation FMMetalView

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        self.device = ZYMetalContext.shared.device;

        self.framebufferOnly = NO;
        self.autoResizeDrawable = NO;
        
        self.paused = YES;
        self.enableSetNeedsDisplay = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    id<MTLCommandBuffer> commandBuffer = render(ZYMetalContext.shared.normalRenderPipelineState, self.currentDrawable.texture, renderTexture, normalVertices, rotateCounterclockwiseCoordinates);
    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];
}

#pragma mark -
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    self.drawableSize = CGSizeMake(renderTexture.width, renderTexture.height);
    [self draw];
}

- (void)setInputFramebuffer:(ZYMetalFrameBuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    renderTexture = newInputFramebuffer.texture;
}

@end
