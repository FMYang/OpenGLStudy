//
//  ProcessTextureWithComputeFuncVC.m
//  LearnMetal
//
//  Created by yfm on 2022/7/12.
//

#import "ProcessTextureWithComputeFuncVC.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "AAPLImage.h"

@interface ProcessTextureWithComputeFuncVC () <MTKViewDelegate> {
    MTKView *_mtkView;
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLComputePipelineState> _computePipelineState;
    id<MTLRenderPipelineState> _renderPipelineState;
    id<MTLTexture> _inputTexture;
    id<MTLTexture> _outputTexture;
    
    // 并行计算参数
    MTLSize _threadgroupSize;
    MTLSize _threadgroupCount;
}
@end

@implementation ProcessTextureWithComputeFuncVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _device = MTLCreateSystemDefaultDevice();
        
    _mtkView = [[MTKView alloc] initWithFrame:self.view.bounds];
    _mtkView.enableSetNeedsDisplay = YES;
    _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    _mtkView.device = _device;
    _mtkView.clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
    _mtkView.delegate = self;
    [self.view addSubview:_mtkView];
    
    NSError *error = NULL;

    _commandQueue = [_device newCommandQueue];
    
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> kernelFunction = [defaultLibrary newFunctionWithName:@"grayscaleKernel"];
    _computePipelineState = [_device newComputePipelineStateWithFunction:kernelFunction error:&error];
    NSAssert(_computePipelineState, @"Failed to create compute pipeline state: %@", error);
    
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"processTextureVertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"processTextureSamplingShader"];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Simple Render Pipeline";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
    
    _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_renderPipelineState, @"Failed to create render pipeline state: %@", error);
    
    NSURL *imageFileLocation = [[NSBundle mainBundle] URLForResource:@"Image" withExtension:@"tga"];
    
    AAPLImage *image = [[AAPLImage alloc] initWithTGAFileAtLocation:imageFileLocation];
    if(!image) {
        return;
    }
    
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.width = image.width;
    textureDescriptor.height = image.height;
    
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    _inputTexture = [_device newTextureWithDescriptor:textureDescriptor];
    
    textureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    _outputTexture = [_device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = {{ 0, 0, 0 }, {textureDescriptor.width, textureDescriptor.height, 1}};
    
    // Calculate the size of each texel times the width of the textures.
    NSUInteger bytesPerRow = 4 * textureDescriptor.width;

    // Copy the bytes from the data object into the texture.
    [_inputTexture replaceRegion:region
                mipmapLevel:0
                  withBytes:image.data.bytes
                bytesPerRow:bytesPerRow];

    NSAssert(_inputTexture && !error, @"Failed to create inpute texture: %@", error);

    // Set the compute kernel's threadgroup size to 16 x 16.
    _threadgroupSize = MTLSizeMake(16, 16, 1);

    // Calculate the number of rows and columns of threadgroups given the size of the
    // input image. Ensure that the grid covers the entire image (or more).
    _threadgroupCount.width  = (_inputTexture.width  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = (_inputTexture.height + _threadgroupSize.height - 1) / _threadgroupSize.height;
    // The image data is 2D, so set depth to 1.
    _threadgroupCount.depth = 1;

    // Create the command queue.
    _commandQueue = [_device newCommandQueue];
}

#pragma mark - delegate
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    
}

- (void)drawInMTKView:(MTKView *)view {
    float position[] = {
         0.5, -0.5,
        -0.5, -0.5,
        -0.5,  0.5,
         0.5, -0.5,
        -0.5,  0.5,
         0.5,  0.5
    };
    
    float texCoordinate[] = {
        1.0, 1.0,
        0.0, 1.0,
        0.0, 0.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 0.0
    };
    

    // Create a new command buffer for each frame.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // Process the input image.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];

    
    [computeEncoder setComputePipelineState:_computePipelineState];

    [computeEncoder setTexture:_inputTexture
                       atIndex:0];

    [computeEncoder setTexture:_outputTexture
                       atIndex:1];
    
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];

    [computeEncoder endEncoding];

    // Use the output image to draw to the view's drawable texture.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil)
    {
        // Create the encoder for the render pass.
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        // Set the region of the drawable to draw into.
//        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

        [renderEncoder setRenderPipelineState:_renderPipelineState];

        // Encode the vertex data.
        id<MTLBuffer> positionBuffer = [_device newBufferWithBytes:position length:sizeof(position) options:MTLResourceStorageModeShared];
        [renderEncoder setVertexBuffer:positionBuffer offset:0 atIndex:0];

        // Encode the viewport data.
        id<MTLBuffer> texCoordinateBuffer = [_device newBufferWithBytes:texCoordinate length:sizeof(texCoordinate) options:MTLResourceStorageModeShared];
        [renderEncoder setVertexBuffer:texCoordinateBuffer offset:0 atIndex:1];

        // Encode the output texture from the previous stage.
        [renderEncoder setFragmentTexture:_outputTexture atIndex:0];

        // Draw the quad.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        [renderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable.
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];

}

#pragma mark -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
