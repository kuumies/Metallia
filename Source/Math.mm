#include "Math.h"

simd_float4x4 perspective(
    float fovY,
    float aspectRatio,
    float zNear,
    float zFar)
{
    const float sy = 1.0f / std::tan(fovY * 0.5f);
    const float sx = sy / aspectRatio;
    const float zRange = zFar - zNear;
    const float sz = -(zFar + zNear) / zRange;
    const float swz = -2.0f * zFar * zNear / zRange;

    return simd_float4x4{
        simd_float4{ sx,  0,   0,    0 },
        simd_float4{ 0,   sy,  0,    0 },
        simd_float4{ 0,   0,   sz,  -1 },
        simd_float4{ 0,   0,   swz,  0 }};
}

simd_float4x4 translate(float x, float y, float z)
{
    return simd_float4x4{
        simd_float4{ 1,  0,  0,  0 },
        simd_float4{ 0,  1,  0,  0 },
        simd_float4{ 0,  0,  1,  0 },
        simd_float4{ x,  y,  z,  1 }};
}

simd_float4x4 translate(const simd_float3& position)
{
    return translate(position[0], position[1], position[2]);
}

simd_float4x4 trs(const simd_float3& position,
                  const simd_quatf& rotation,
                  const simd_float3& s)
{
    simd_float4x4 m = matrix_identity_float4x4;
    m = translate(position);
    m = matrix_multiply(simd_matrix4x4(rotation), m);
    m = matrix_multiply(scale(s), m);
    return m;
}

simd_float4x4 scale(float sx, float sy, float sz)
{
    return simd_float4x4{
        simd_float4{ sx,   0,   0,  0 },
        simd_float4{  0,  sy,   0,  0 },
        simd_float4{  0,   0,  sz,  0 },
        simd_float4{  0,   0,   0,  1 }};
}

simd_float4x4 scale(const simd_float3& s)
{
    return scale(s[0], s[1], s[2]);
}
