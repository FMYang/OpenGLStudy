//
//  ZYMetalBaseFilter.h
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/13.
//

#import <Foundation/Foundation.h>
#import "ZYMetalDevice.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZYMetalProcessing <NSObject>

- (id<MTLTexture>)render:(id<MTLTexture>)inputTexture;

@end

@protocol ZYMetalFilterFunction <NSObject>

@property (nonatomic, readonly) NSString *functionName;

@end

@protocol ZYMetalFilterRenderCommand <ZYMetalFilterFunction>

- (id<MTLRenderCommandEncoder>)encodeMetalCommand:(id<MTLCommandBuffer>)commandBuffer
                                    pipelineState:(id<MTLRenderPipelineState>)pipelineState
                                     inputTexture:(id<MTLTexture>)inputTexture
                                    outputTexture:(id<MTLTexture>)outputTexture
                                           device:(id<MTLDevice>)device;

@end

@interface ZYMetalBaseFilter : NSObject <ZYMetalProcessing>

@property (nonatomic) CVPixelBufferRef outputPixelBuffer;

- (instancetype)initWithMetalRenderCommand:(id<ZYMetalFilterRenderCommand>)metalRenderCommand;

@end

NS_ASSUME_NONNULL_END
