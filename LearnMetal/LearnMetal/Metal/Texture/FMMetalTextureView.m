//
//  FMMetalTextureView.m
//  LearnMetal
//
//  Created by yfm on 2021/10/13.

/**
 纹理坐标系
 原点在左上角
 0.0, 0.0    1.0,0.0
 -------------------
 |                 |
 |                 |
 |                 |
 |                 |
 -------------------
 0.0, 1.0    1.0,1.0
 
 metal坐标系
 原点在左上角
 -1.0, 1.0   1.0,1.0
 -------------------
 |                 |
 |                 |
 |                 |
 |                 |
 -------------------
 -1.0, -1.0  1.0,-1.0
 */


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
            
//            // 右旋转90度，3.jpeg
//            { {  -1.0,  1.0 },  { 0.0, 1.0 } },
//            { { 1.0,  1.0 },  { 0.0, 0.0 } },
//            { { -1.0,   -1.0 },  { 1.0, 1.0 } },
//
//            { {  1.0,  1.0 },  { 0.0, 0.0 } },
//            { { -1.0,   -1.0 },  { 1.0, 1.0 } },
//            { {  1.0,   -1.0 },  { 1.0, 0.0 } },
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
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";

        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];

        // 使用这个渲染管线state对象来进行图元绘制
        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBuffer:_vertices
                                offset:0
                              atIndex:FMVertexInputIndexVertices];

        [renderEncoder setFragmentTexture:_texture
                                  atIndex:FMTextureIndexBaseColor];
        
        // 绘制顶点构成的图元
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}


#pragma mark - 加载纹理
// 通过MTKTextureLoader加载纹理
- (id<MTLTexture>)loadTexture {
    UIImage *image = [UIImage imageNamed:@"1.jpeg"];
    CGImageRef imageRef = image.CGImage;
    MTKTextureLoader*loader = [[MTKTextureLoader alloc]initWithDevice:_device];
    NSError*error;
    id<MTLTexture> texture = [loader newTextureWithCGImage:imageRef options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:&error];
    return texture;
}

// 通过位图加载纹理
- (id<MTLTexture>)loadTexture1 {
    UIImage *image = [UIImage imageNamed:@"3.jpeg"];
    
    CGImageRef imageRef = image.CGImage;
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    GLubyte *textureData = (GLubyte *)malloc(width * height * 4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(textureData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGColorSpaceRelease(colorSpace);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);

    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    id<MTLTexture> texture = [_device newTextureWithDescriptor:textureDescriptor];
    MTLRegion region = {
        { 0, 0, 0 },
        {width, height, 1}
    };
    [texture replaceRegion:region
                mipmapLevel:0
                  withBytes:textureData
                bytesPerRow:bytesPerRow];
    return texture;

}

@end
