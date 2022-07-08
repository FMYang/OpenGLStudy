//
//  CustomRenderer.m
//  LearnMetal
//
//  Created by yfm on 2022/7/8.
//

#import "CustomRenderer.h"

@interface CustomRenderer() {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLBuffer> _vertices;
    id<MTLTexture> _depthTarget;
    
    MTLRenderPassDescriptor *_drawableRenderPassDescriptor;
    NSUInteger _frameNum;
}

@end

@implementation CustomRenderer

- (nonnull instancetype)initWithMetalDevice:(nonnull id<MTLDevice>)device
                        drawablePixelFormat:(MTLPixelFormat)drawablePixelFormat {
    if(self = [super init]) {
        _frameNum = 0;
        _device = device;
        _commandQueue = [_device newCommandQueue];
        
        _drawableRenderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        _drawableRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _drawableRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _drawableRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 1, 1);
        
        {
            id<MTLLibrary> shaderLib = [_device newDefaultLibrary];
            if(!shaderLib) {
                NSLog(@" ERROR: Couldnt create a default shader library");
                return nil;
            }
            
            id<MTLFunction> vertexProgram = [shaderLib newFunctionWithName:@"customMTKViewVertexShader"];
            if(!vertexProgram) {
                NSLog(@">> ERROR: Couldn't load vertex function from default library");
                return nil;
            }

            id<MTLFunction> fragmentProgram = [shaderLib newFunctionWithName:@"customMTKViewFragmentShader"];
            if(!fragmentProgram) {
                NSLog(@" ERROR: Couldn't load fragment function from default library");
                return nil;
            }
            
            float quadVertices[] = {
                 0.5, -0.5,
                -0.5, -0.5,
                -0.5,  0.5,
                 0.5, -0.5,
                -0.5,  0.5,
                 0.5,  0.5
            };
            
            _vertices = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
            _vertices.label = @"Quad";
            
            MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
            pipelineDescriptor.label = @"MyPipeline";
            pipelineDescriptor.vertexFunction = vertexProgram;
            pipelineDescriptor.fragmentFunction = fragmentProgram;
            pipelineDescriptor.colorAttachments[0].pixelFormat = drawablePixelFormat;
            
            NSError *error;
            _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
            if(!_pipelineState) {
                NSLog(@"ERROR: Failed aquiring pipeline state: %@", error);
                return nil;
            }
        }
    }
    return self;
}

- (void)renderToMetalLayer:(nonnull CAMetalLayer *)metalLayer {
    _frameNum++;
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    id<CAMetalDrawable> currentDrawable = [metalLayer nextDrawable];
    
    if(!currentDrawable) {
        return;
    }
    
    _drawableRenderPassDescriptor.colorAttachments[0].texture = currentDrawable.texture;
    
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_drawableRenderPassDescriptor];
    
    [renderEncoder setRenderPipelineState:_pipelineState];
    
    [renderEncoder setVertexBuffer:_vertices offset:0 atIndex:0];
    
    {
        // 随时间线性（sin）缩放图形
        float scale = 0.5 + (1.0 + 0.5 * sin(_frameNum * 0.1));

        // 将缩放倍数传入顶点着色器
        id<MTLBuffer> scaleBuffer = [_device newBufferWithBytes:&scale length:sizeof(scale) options:MTLResourceStorageModeShared];
        [renderEncoder setVertexBuffer:scaleBuffer offset:0 atIndex:1];
    }
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    
    [renderEncoder endEncoding];
    
    [commandBuffer presentDrawable:currentDrawable];
    
    [commandBuffer commit];
}

- (void)drawableResize:(CGSize)drawableSize {
    
}

@end
