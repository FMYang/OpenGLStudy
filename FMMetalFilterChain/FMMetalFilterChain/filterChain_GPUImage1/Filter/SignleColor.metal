//
//  SignleColor.metal
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/26.
//

#include <metal_stdlib>
using namespace metal;

struct VextexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

fragment float4 singleColorFilterFragmentShader(VextexOut in [[ stage_in ]],
                                                texture2d<half> inputTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    half4 color = inputTexture.sample(textureSampler, in.textureCoordinate);
    return float4(color.r, 0.0, 0.0, 1.0);
}

