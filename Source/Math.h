#pragma once

#include <simd/simd.h>

// Creates a left-handed perspective projection matrix
simd_float4x4 perspective(float fovY, float aspect, float zNear, float zFar);

// Creates a translation matrix
simd_float4x4 translate(float x, float y, float z);
simd_float4x4 translate(const simd_float3& position);

// Creates a scale matrix
simd_float4x4 scale(float sx, float sy, float sz);
simd_float4x4 scale(const simd_float3& s);

// Creates a translation-rotation-scale matrix
simd_float4x4 trs(
    const simd_float3& position,
    const simd_quatf& rotation,
    const simd_float3& scale);
