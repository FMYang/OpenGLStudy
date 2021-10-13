//
//  FMMetalTextureView.m
//  LearnMetal
//
//  Created by yfm on 2021/10/13.
//

#import "FMMetalTextureView.h"
#import "FMShaderTypes.h"

@interface FMMetalTextureView() <MTKViewDelegate> {
    id<MTLDevice> _device;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLCommandQueue> _commandQueue;
    id<MTLTexture> _texture;
    id<MTLBuffer> _vertices;
    NSUInteger _numVertices;
    vector_uint2 _viewportSize;
}

@end

@implementation FMMetalTextureView

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        _device = MTLCreateSystemDefaultDevice();
        self.device = _device;

        _texture = [self loadTexture];
        
        static const FMVertex quadVertices[] = {
            // 顶点坐标, 纹理坐标
            { {  -1.0,  1.0 },  { 0.0, 0.0 } },
            { { 1.0,  1.0 },  { 1.0, 0.0 } },
            { { -1.0,   -1.0 },  { 0.0, 1.0 } },

            { {  1.0,  1.0 },  { 1.0, 0.0 } },
            { { -1.0,   -1.0 },  { 0.0, 1.0 } },
            { {  1.0,   -1.0 },  { 1.1, 1.1 } },
        };
        
        _vertices = [_device newBufferWithBytes:quadVertices
                                         length:sizeof(quadVertices)
                                        options:MTLResourceStorageModeShared];

        _numVertices = sizeof(quadVertices) / sizeof(FMVertex);

        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"textureVertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"textureSamplingShader"];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Texturing Pipeline";
        pipelineStateDescriptor.vertexFunction = vertexFunction;
        pipelineStateDescriptor.fragmentFunction = fragmentFunction;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;

        NSError *error = NULL;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                                 error:&error];

        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);

        _commandQueue = [_device newCommandQueue];
        
        // 设置缓冲区初始大小
        [self mtkView:self drawableSizeWillChange:self.drawableSize];
        self.delegate = self;
    }
    return self;
}

#pragma mark - MTKViewDelegate
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    // Save the size of the drawable to pass to the vertex shader.
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    // Create a new command buffer for each render pass to the current drawable
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil)
    {
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set the region of the drawable to draw into.
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBuffer:_vertices
                                offset:0
                              atIndex:FMVertexInputIndexVertices];

        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:FMVertexInputIndexViewportSize];

        // Set the texture object.  The FMTextureIndexBaseColor enum value corresponds
        ///  to the 'colorMap' argument in the 'samplingShader' function because its
        //   texture attribute qualifier also uses FMTextureIndexBaseColor for its index.
        [renderEncoder setFragmentTexture:_texture
                                  atIndex:FMTextureIndexBaseColor];

        // Draw the triangles.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];

        [renderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
}


#pragma mark -
// 加载纹理
- (id<MTLTexture>)loadTexture {
    UIImage *image = [UIImage imageNamed:@"1.jpeg"];
    CGImageRef imageRef = image.CGImage;
    MTKTextureLoader*loader = [[MTKTextureLoader alloc]initWithDevice:_device];
    NSError*error;
    id<MTLTexture> texture = [loader newTextureWithCGImage:imageRef options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:&error];
    return texture;
}


@end
