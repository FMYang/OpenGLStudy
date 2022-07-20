//
//  Gray.metal
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/14.
//

#include <metal_stdlib>
using namespace metal;

struct VextexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

fragment float4 grayFragmentShader(VextexOut in [[ stage_in ]],
                           texture2d<half> inputTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    half4 color = inputTexture.sample(textureSampler, in.textureCoordinate);
    float average = (color.r + color.g + color.b) / 3.0;
    return float4(average, average, average, 1.0);
}

