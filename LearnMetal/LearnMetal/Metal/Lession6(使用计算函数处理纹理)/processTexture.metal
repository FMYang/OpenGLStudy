//
//  processTexture.metal
//  LearnMetal
//
//  Created by yfm on 2022/7/12.
//

#include <metal_stdlib>
using namespace metal;

struct RasterizerData
{
    float4 clipSpacePosition [[position]];

    float2 textureCoordinate;

};

// Vertex Function
vertex RasterizerData
processTextureVertexShader(uint vertexID [[ vertex_id ]],
             constant float2* positionVertexArray  [[ buffer(0) ]],
             constant float2* texVertexArray  [[ buffer(1) ]]) {

    RasterizerData out;

    // Index into the array of positions to get the current vertex
    // Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    // the origin)
    float2 pixelSpacePosition = positionVertexArray[vertexID].xy;

    // In order to convert from positions in pixel space to positions in clip space, divide the
    //   pixel coordinates by half the size of the viewport.
    out.clipSpacePosition.xy = float2(pixelSpacePosition.x * 2, pixelSpacePosition.y);
    out.clipSpacePosition.z = 0.0;
    out.clipSpacePosition.w = 1.0;

    // Pass the input textureCoordinate straight to the output RasterizerData.  This value will be
    //   interpolated with the other textureCoordinate values in the vertices that make up the
    //   triangle.
    out.textureCoordinate = texVertexArray[vertexID];

    return out;
}

// Fragment function
fragment float4
processTextureSamplingShader(RasterizerData  in           [[stage_in]],
                               texture2d<half> colorTexture [[ texture(0) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture and return the color to colorSample
    const half4 colorSample = colorTexture.sample (textureSampler, in.textureCoordinate);
    return float4(colorSample);
}

// Rec. 709 luma values for grayscale image conversion
constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

// Grayscale compute kernel
kernel void
grayscaleKernel(texture2d<half, access::read>  inTexture  [[texture(0)]],
                texture2d<half, access::write> outTexture [[texture(1)]],
                uint2                          gid        [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }

    half4 inColor  = inTexture.read(gid);
    half  gray     = dot(inColor.rgb, kRec709Luma);
    outTexture.write(half4(gray, gray, gray, 1.0), gid);
}
