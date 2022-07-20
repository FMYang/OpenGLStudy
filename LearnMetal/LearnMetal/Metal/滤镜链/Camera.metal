//
//  Camera.metal
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

vertex VextexOut cameraVertex(uint vertexID [[ vertex_id ]],
                           constant float2 *position [[ buffer(0) ]],
                           constant float2 *texCoordinate [[ buffer(1) ]]) {
    VextexOut out;
    out.position = float4(position[vertexID].xy, 0.0, 1.0);
    out.textureCoordinate = texCoordinate[vertexID];
    return out;
}

fragment float4 cameraFrag(VextexOut in [[ stage_in ]],
                           texture2d<half> videoTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    const half4 color = videoTexture.sample(textureSampler, in.textureCoordinate);
    return float4(color);
}
