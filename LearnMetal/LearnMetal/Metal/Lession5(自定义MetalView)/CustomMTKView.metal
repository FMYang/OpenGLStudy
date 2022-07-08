//
//  CustomMTKView.metal
//  LearnMetal
//
//  Created by yfm on 2022/7/8.
//

#include <metal_stdlib>
using namespace metal;

vertex float4
customMTKViewVertexShader(uint vertexID [[vertex_id]],
                    constant float2 *vertices [[ buffer(0) ]],
                    constant float &scale [[ buffer(1) ]]) {
    float2 pixelSpacePosition = float2(vertices[vertexID].x, vertices[vertexID].y/2);

    pixelSpacePosition *= scale;
    
    return float4(pixelSpacePosition, 0.0, 1.0);
}

fragment float4
customMTKViewFragmentShader() {
    return float4(1.0, 0.0, 0.0, 1.0);
}
