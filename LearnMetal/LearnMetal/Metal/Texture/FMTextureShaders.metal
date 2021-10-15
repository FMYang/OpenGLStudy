/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
 
所有使用了 Metal 函数修饰符的函数 (vertex, fragment,或 kernel) 可以在 MTLLibrary 中被表示为一个 MTLFunction 对象
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#include "FMShaderTypes.h"

struct RasterizerData {
    float4 position [[position]];
    float2 textureCoordinate;
};

// vertex修饰的函数textureVertexShader表示顶点着色器
vertex RasterizerData
textureVertexShader(uint vertexID [[ vertex_id ]],
             constant FMVertex *vertexArray [[ buffer(FMVertexInputIndexVertices) ]]) {

    RasterizerData out;

    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

// fragment修饰的函数textureSamplingShader表示片元着色器
fragment float4
textureSamplingShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(FMTextureIndexBaseColor) ]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    return float4(colorSample);
}

