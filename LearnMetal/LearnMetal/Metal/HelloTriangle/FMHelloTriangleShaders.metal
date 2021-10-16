//
//  FMHelloTriangleShaders.metal
//  LearnMetal
//
//  Created by yfm on 2021/10/15.
//

#include <metal_stdlib>

using namespace metal;

struct VertexOutput {
    float4 position [[ position ]];
    float4 color_data;
};

vertex VertexOutput
hello_vertex(const device float4 *pos_data [[ buffer(0) ]],
             const device float4 *color_data [[ buffer(1) ]],
             uint vertexID [[vertex_id]]) {
    VertexOutput out;
    
    out.position = pos_data[vertexID];
    out.color_data = color_data[vertexID];
    
    return out;
}

fragment half4
hello_frament(VertexOutput in [[ stage_in ]]) {
    return half4(in.color_data);
}
