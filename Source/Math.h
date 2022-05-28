#pragma once

#include <simd/simd.h>

// Creates a perspective projection matrix
simd_float4x4 perspective(
    float fovY,
    float aspectRatio,
    float zNear,
    float zFar);

// Creates translation matrix
simd_float4x4 translate(float x, float y, float z);
