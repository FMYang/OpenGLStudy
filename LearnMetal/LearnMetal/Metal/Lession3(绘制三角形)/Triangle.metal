//
//  Triangle.metal
//  LearnMetal
//
//  Created by yfm on 2022/7/6.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
};

vertex float4
triangleVertextShader(uint vertexID [[vertex_id]],
                      constant float2 *vertices [[ buffer(0) ]]) {
//    Vertex vert;
//    vert.position = float4(vertices[vertexID], 0.0, 1.0);
//    return vert.position;
    return float4(vertices[vertexID], 0.0, 1.0);
}

fragment float4
triangleFragmentShader(float4 in [[stage_in]]) {
    return float4(1.0, 0.0, 0.0, 1.0);
}

