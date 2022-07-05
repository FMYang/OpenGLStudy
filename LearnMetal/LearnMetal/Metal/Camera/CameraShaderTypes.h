//
//  CameraShaderTypes.h
//  LearnMetal
//
//  Created by yfm on 2022/7/4.
//

#ifndef CameraShaderTypes_h
#define CameraShaderTypes_h

#include <simd/simd.h>

typedef enum FMVertexInputIndex
{
    FMVertexInputIndexVertices     = 0,
} FMVertexInputIndex;

typedef enum FMTextureIndex
{
    FMTextureIndexBaseColor = 0,
} FMTextureIndex;

typedef struct
{
    vector_float2 position;
    vector_float2 textureCoordinate;
} FMVertex;

#endif /* CameraShaderTypes_h */
