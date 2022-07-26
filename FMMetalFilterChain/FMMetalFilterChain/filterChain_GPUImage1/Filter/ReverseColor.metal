//
//  ReverseColor.metal
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/20.
//

#include <metal_stdlib>
using namespace metal;

struct VextexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

fragment float4 reverseColorFragmentShader(VextexOut in [[ stage_in ]],
                                           texture2d<half> inputTexture [[ texture(0) ]],
                                           texture2d<half> ouputTexture [[ texture(1) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    half4 color = inputTexture.sample(textureSampler, in.textureCoordinate);
    return float4(1 - color.r, 1 - color.g, 1 - color.b, 1.0);
}
