//
//  CameraMetal.metal
//  LearnMetal
//
//  Created by yfm on 2021/10/17.
//

#include <metal_stdlib>
using namespace metal;

struct VextexIn {
    float2 position;
    float2 textureCoordinate;
};

struct VextexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

vertex VextexOut cameraVertex(const device VextexIn *in [[ buffer(0) ]],
                              uint vertexID [[ vertex_id ]]) {
    VextexOut out;
    out.position = float4(in[vertexID].position.xy, 0.0, 1.0);
    out.textureCoordinate = in[vertexID].textureCoordinate;
    return out;
}

fragment float4 cameraFrag(VextexOut in [[ stage_in ]],
                           texture2d<half> colorTexture [[ texture(0) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);

}
