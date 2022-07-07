//
//  CustomRenderPass.metal
//  LearnMetal
//
//  Created by yfm on 2022/7/7.
//

#include <metal_stdlib>
using namespace metal;

#pragma mark - 离屏纹理渲染shader

/**
 顶点着色器，将顶点数据传入光栅化阶段，生成片元
 */
vertex float4
customTextureVertextShader(uint vertexID [[vertex_id]],
                      constant float2 *vertices [[ buffer(0) ]]) {
    return float4(vertices[vertexID], 0.0, 1.0);;
}

/**
 片段着色器，给片元着色
 */
fragment float4
customTextureFragmentShader(float4 in [[stage_in]]) {
    return float4(0.0, 1.0, 0.0, 1.0);
}

#pragma mark - 显示在屏幕上的shader

// 光栅化数据结构
struct TexturePipelineRasterizerData
{
    float4 position [[position]];
    float2 texcoord;
};

vertex TexturePipelineRasterizerData
customDrawableVertextShader(uint vertexID [[vertex_id]],
                      constant float2 *vertices [[ buffer(0) ]],
                      constant float2 *tex [[ buffer(1) ]]) {
    TexturePipelineRasterizerData out;

    // 保存顶点坐标
    out.position = float4(vertices[vertexID].x * 2, vertices[vertexID].y, 0.0, 1.0);
    // 保存纹理坐标
    out.texcoord = tex[vertexID];
    
    return out;
}

fragment float4
customDrawableFragmentShader(TexturePipelineRasterizerData in [[stage_in]],
                             texture2d<float> texture [[texture(0)]]) {
    sampler simpleSampler;

    // 使用输入的纹理采样数据
    float4 color = texture.sample(simpleSampler, in.texcoord);
    
    return color;
}
