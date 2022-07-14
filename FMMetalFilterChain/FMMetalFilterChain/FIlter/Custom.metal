//
//  Custom.metal
//  FMMetalFilterChain
//
//  Created by yfm on 2022/7/13.
//

#include <metal_stdlib>
using namespace metal;

struct VextexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

vertex VextexOut normalVertex(uint vertexID [[ vertex_id ]],
                              constant float2 *position [[ buffer(0) ]],
                              constant float2 *texCoordinate [[ buffer(1) ]]) {
    VextexOut out;
    out.position = float4(position[vertexID].xy, 0.0, 1.0);
    out.textureCoordinate = texCoordinate[vertexID];
    return out;
}

fragment float4 customFragmentShader(VextexOut in [[ stage_in ]],
                           texture2d<half> inputTexture [[ texture(0) ]],
                           texture2d<half> ouputTexture [[ texture(1) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float r = inputTexture.sample(textureSampler, in.textureCoordinate).r;
    float g = inputTexture.sample(textureSampler, in.textureCoordinate).g;
    float b = inputTexture.sample(textureSampler, in.textureCoordinate).b;
    return float4(1 - r, 1 - g, 1 - b, 1.0);
}
