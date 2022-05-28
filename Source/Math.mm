#include "Math.h"

simd_float4x4 perspective(
    float fovY,
    float aspectRatio,
    float zNear,
    float zFar)
{
    float ys = 1.0f / tanf(fovY * 0.5);
    float xs = ys / aspectRatio;
    float zs = zFar / (zFar - zNear);

    return simd_matrix_from_rows(
        simd_float4{ xs,  0,   0,   0           },
        simd_float4{ 0,   ys,  0,   0           },
        simd_float4{ 0,   0,   zs,  -zNear * zs },
        simd_float4{ 0,   0,   1,   0           }
    );

#if 0
    return matrix_identity_float4x4;
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (farZ - nearZ);
    return matrix_make_rows(xs,  0,  0,           0,
                             0, ys,  0,           0,
                             0,  0, zs, -nearZ * zs,
                             0,  0,  1,           0 );
#endif
}

matrix_float4x4 translate(float x, float y, float z)
{
    return matrix_identity_float4x4;
}
