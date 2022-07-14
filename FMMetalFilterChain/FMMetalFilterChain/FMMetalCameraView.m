//
//  FMMetalCameraView.m
//  LearnMetal
//
//  Created by yfm on 2021/10/17.
//

#import "FMMetalCameraView.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "ZYMetalDevice.h"

@interface FMMetalCameraView() {
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLTexture> renderTexture;
}

@end

@implementation FMMetalCameraView

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        self.device = ZYMetalDevice.shared.device;
        
        self.framebufferOnly = NO;
        self.autoResizeDrawable = NO;
        self.paused = NO;
        self.enableSetNeedsDisplay = NO;
                
        id<MTLFunction> vextexFunction = [ZYMetalDevice.shared.library newFunctionWithName:@"cameraVertex"];
        id<MTLFunction> fragmentFunction = [ZYMetalDevice.shared.library newFunctionWithName:@"cameraFrag"];
        
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.vertexFunction = vextexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        
        NSError *error;
        _pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];

        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
    }
    return self;
}

- (void)renderPixelBuffer:(id<MTLTexture>)inputTexture {
    NSLog(@"%@", [NSThread currentThread]);
    self.drawableSize = CGSizeMake(inputTexture.width, inputTexture.height);
    renderTexture = inputTexture;
    [self draw11];
}

- (void)draw11 {
    if(!self.currentDrawable || !renderTexture) return;
    
    id<MTLTexture> tmpTexture = renderTexture;
    id<MTLCommandBuffer> commandBuffer = [ZYMetalDevice.shared.commandQueue commandBuffer];

    MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
    renderPassDescriptor.colorAttachments[0].texture = self.currentDrawable.texture;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1);
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;

    if(renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        id<MTLBuffer> positionBuffer = [self.device newBufferWithBytes:normalVertices length:sizeof(normalVertices) options:MTLResourceStorageModeShared];
        id<MTLBuffer> texCoordinateBuffer = [self.device newBufferWithBytes:rotateCounterclockwiseCoordinates length:sizeof(rotateCounterclockwiseCoordinates) options:MTLResourceStorageModeShared];

        // 正面图元的缠绕规则，三角形是顺时针还是逆时针绘制
        [renderEncoder setFrontFacingWinding:MTLWindingClockwise];
        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];
        [renderEncoder setVertexBuffer:texCoordinateBuffer offset:0 atIndex:1];
        [renderEncoder setFragmentTexture:tmpTexture atIndex:0];

        // 绘制顶点构成的图元
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:self.currentDrawable];
//        [commandBuffer presentDrawable:self.currentDrawable.layer.nextDrawable];

        [commandBuffer commit];
    } else {
        NSLog(@"renderPassDescriptor nil");
    }
}

@end
