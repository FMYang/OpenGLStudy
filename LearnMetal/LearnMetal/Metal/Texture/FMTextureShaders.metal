/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#include "FMShaderTypes.h"

struct RasterizerData {
    float4 position [[position]];
    float2 textureCoordinate;
};

// 顶点着色器
vertex RasterizerData
textureVertexShader(uint vertexID [[ vertex_id ]],
             constant FMVertex *vertexArray [[ buffer(FMVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(FMVertexInputIndexViewportSize) ]]) {

    RasterizerData out;

    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

// 片元着色器
fragment float4
textureSamplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(FMTextureIndexBaseColor) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
}

