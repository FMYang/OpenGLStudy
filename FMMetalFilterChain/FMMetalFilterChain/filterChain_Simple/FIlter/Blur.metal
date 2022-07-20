//
//  Blur.metal
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

fragment float4 mpsFragmentShader(VextexOut in [[ stage_in ]],
                           texture2d<half> inputTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    return float4(inputTexture.sample(textureSampler, in.textureCoordinate));
}

