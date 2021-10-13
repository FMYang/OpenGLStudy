/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and C/ObjC source
*/

#ifndef FMShaderTypes_h
#define FMShaderTypes_h

#include <simd/simd.h>

typedef enum FMVertexInputIndex
{
    FMVertexInputIndexVertices     = 0,
    FMVertexInputIndexViewportSize = 1,
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

#endif /* FMShaderTypes_h */
