//
//  CameraMetal.metal
//  LearnMetal
//
//  Created by yfm on 2021/10/17.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "CameraShaderTypes.h"

using namespace metal;

struct VextexIn {
    float2 position;
    float2 textureCoordinate;
};

struct VextexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

vertex VextexOut cameraVertex(uint vertexID [[ vertex_id ]],
                              constant FMVertex *vertexArray [[ buffer(FMVertexInputIndexVertices) ]]) {
    VextexOut out;
    out.position = float4(vertexArray[vertexID].position.xy, 0.0, 1.0);
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment float4 cameraFrag(VextexOut in [[ stage_in ]],
                           texture2d<half> colorTexture [[ texture(FMTextureIndexBaseColor) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
}
