/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>

using namespace metal;

#include "FMTriangleShaderTypes.h"

/**
 告诉 Metal 光栅化数据中的哪个字段提供位置数据，因为 Metal 不会对结构中的字段强制执行任何特定的命名约定。
 使用属性限定符注释该position字段[[position]]以声明该字段持有输出位置。
 */
struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

/**
 声明顶点函数，包括它的输入参数和它输出的数据。就像使用关键字kernel声明计算函数一样，您使用关键字vertex声明顶点函数。
 
 第一个参数 ,使用属性限定符，这是另一个 Metal 关键字。当您执行渲染命令时，GPU 会多次调用您的顶点函数，为每个顶点生成一个唯一值。vertexID[[vertex_id]]

 第二个参数vertices是一个包含顶点数据的数组，使用AAPLVertex之前定义的结构。
 */
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant AAPLVertex *vertices [[buffer(AAPLVertexInputIndexVertices)]]) {
    RasterizerData out;

    float2 pixelSpacePosition = vertices[vertexID].position.xy;

    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition;

    out.color = vertices[vertexID].color;

    return out;
}

/**
 片段函数只是将光栅化阶段的数据传递到后面的阶段，因此它不需要任何额外的参数。
 */
fragment float4
fragmentShader(RasterizerData in [[stage_in]]) {
    return in.color;
}

