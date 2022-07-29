//
//  ZYHisFilter.m
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/29.
//

#import "ZYHisFilter.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#include <simd/simd.h>

@implementation ZYHisFilter

- (id<MTLRenderCommandEncoder>)encodeMetalCommand:(id<MTLCommandBuffer>)commandBuffer
                                    pipelineState:(id<MTLRenderPipelineState>)pipelineState
                                     inputTexture:(id<MTLTexture>)inputTexture
                                    outputTexture:(id<MTLTexture>)outputTexture
                                           device:(nonnull id<MTLDevice>)device {
    // 直方图均衡化
    MPSImageHistogramInfo info;
    info.histogramForAlpha = YES;
    info.numberOfHistogramEntries = 256;
    info.minPixelValue = simd_make_float4(0, 0, 0, 0);
    info.maxPixelValue = simd_make_float4(1, 1, 1, 1);

    MPSImageHistogram *histogram = [[MPSImageHistogram alloc] initWithDevice:device histogramInfo:&info];
    size_t length = [histogram histogramSizeForSourceFormat:inputTexture.pixelFormat];

    id<MTLBuffer> histogramBuffer = [device newBufferWithLength:length options:MTLResourceStorageModePrivate];
    [histogram encodeToCommandBuffer:commandBuffer sourceTexture:inputTexture histogram:histogramBuffer histogramOffset:0];

    // 定义直方图均衡化对象
    MPSImageHistogramEqualization *equalization = [[MPSImageHistogramEqualization alloc] initWithDevice:device histogramInfo:&info];
    // 根据直方图计算累加直方图数据
    [equalization encodeTransformToCommandBuffer:commandBuffer sourceTexture:inputTexture histogram:histogramBuffer histogramOffset:0];
    // 最后进行均衡化处理
    [equalization encodeToCommandBuffer:commandBuffer sourceTexture:inputTexture destinationTexture:outputTexture];

    return nil;
}

- (NSString *)functionName {
    return @"normalFragmentShader";
}

@end
