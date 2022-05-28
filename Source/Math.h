#pragma once

#include <simd/simd.h>

// Creates a perspective projection matrix
simd_float4x4 perspective(
    float fovY,
    float aspectRatio,
    float zNear,
    float zFar);

// Creates translation matrix
matrix_float4x4 translate(float x, float y, float z);

//matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_make_rows(
//                                   float m00, float m10, float m20, float m30,
//                                   float m01, float m11, float m21, float m31,
//                                   float m02, float m12, float m22, float m32,
//                                   float m03, float m13, float m23, float m33) {
//    return (matrix_float4x4){ {
//        { m00, m01, m02, m03 },     // each line here provides column data
//        { m10, m11, m12, m13 },
//        { m20, m21, m22, m23 },
//        { m30, m31, m32, m33 } } };
//}

