#ifndef COMMON_H
#define COMMON_H

#include <simd/simd.h>

enum VertexAttributeIndex
{
    Position = 0,
    Color    = 1
};

enum BufferIndex  {
    MeshVertexBuffer = 0,
    FrameUniformBuffer = 1,
};

struct Uniforms
{
    simd::float4x4 projectionViewModel;
};

#endif
