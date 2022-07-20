//
//  ZYMetalBaseFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/13.
//

#import "ZYMetalBaseFilter.h"

@interface ZYMetalBaseFilter() {
    dispatch_semaphore_t frameRenderingSemaphore;
}

@property (nonatomic, readonly) id<MTLFunction> function;
@property (nonatomic, readonly) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic) CVMetalTextureRef outputTexture;

@end

@implementation ZYMetalBaseFilter {
    id<ZYMetalFilterRenderCommand> _metalRenderCommand;
}
@synthesize function = _function;
@synthesize renderPipelineState = _renderPipelineState;

- (instancetype)initWithMetalRenderCommand:(id<ZYMetalFilterRenderCommand>)metalRenderCommand {
    if(self = [super init]) {
        _metalRenderCommand = metalRenderCommand;
        
        // 创建一个null的pixelbuffer与outputTexture绑定
        CFDictionaryRef empty; // empty value for attr value.
        CFMutableDictionaryRef attrs;
        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);

        CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault, 1280, 720, kCVPixelFormatType_32BGRA, attrs, &_outputPixelBuffer);
        NSAssert(result == kCVReturnSuccess, @"create pixel failed");
        CFRelease(attrs);
        CFRelease(empty);

        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, ZYMetalDevice.shared.textureCache, self.outputPixelBuffer, nil, MTLPixelFormatBGRA8Unorm, CVPixelBufferGetWidth(self.outputPixelBuffer), CVPixelBufferGetHeight(self.outputPixelBuffer), 0, &_outputTexture);
    }
    return self;
}

#pragma mark - processing
- (id<MTLTexture>)render:(id<MTLTexture>)inputTexture {
    id<MTLRenderPipelineState> pipelineState = self.renderPipelineState;
    if(!pipelineState) return inputTexture;
    
    CVMetalTextureCacheRef textureCacheRef = ZYMetalDevice.shared.textureCache;
    if(!textureCacheRef) return inputTexture;
    
    id<MTLCommandQueue> commandQueue = ZYMetalDevice.shared.commandQueue;
    if(!commandQueue) return inputTexture;
        
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    NSAssert(_metalRenderCommand, @"Metal module must be initialized with an ZYMetalRenderCommand");
    
    id<MTLRenderCommandEncoder> renderCommandEncoder = [_metalRenderCommand encodeMetalCommand:commandBuffer pipelineState:pipelineState inputTexture:inputTexture outputTexture:CVMetalTextureGetTexture(_outputTexture) device:ZYMetalDevice.shared.device];
    
    [renderCommandEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
        
    return CVMetalTextureGetTexture(_outputTexture);
}

#pragma mark - Lazy properties

- (id<MTLFunction>)function {
    return [ZYMetalDevice.shared.library newFunctionWithName:[_metalRenderCommand functionName]];
}

- (id<MTLRenderPipelineState>)renderPipelineState {
    if(!_renderPipelineState) {
        NSError *error = nil;
        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        renderPipelineDescriptor.vertexFunction = [ZYMetalDevice.shared.library newFunctionWithName:@"normalVertex"];
        renderPipelineDescriptor.fragmentFunction = self.function;

        _renderPipelineState = [ZYMetalDevice.shared.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
        NSAssert(error == nil, @"Error while creating render pass pipeline state %@", error);
    }
    return _renderPipelineState;
}

@end
