//
//  FMHelloTriangleShaders.metal
//  LearnMetal
//
//  Created by yfm on 2021/10/15.
//

#include <metal_stdlib>

using namespace metal;

struct VertexOutput {
    float4 postion [[ position ]];
    float4 color_data;
};

vertex VertexOutput
hello_vertex(const device float4 *pos_data [[ buffer(0) ]],
             const device float4 *color_data [[ buffer(1) ]]) {
    VertexOutput out;
    
    out.postion = pos_data[0];
    out.color_data = color_data[0];
    
    return out;
}

fragment half4
hello_frament(VertexOutput in [[ stage_in ]]) {
    return half4(in.color_data);
}
