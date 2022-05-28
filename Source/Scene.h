#pragma once

#include <array>
#include <stdint.h>
#include <simd/simd.h>

struct Vertex
{
    float position[3];
    uint8_t color[4];
};

struct Triangle
{
    Triangle();

    std::array<Vertex, 3> vertices;

    simd_float4x4 transform;

    void updateRotationAnimation(float angleRad);
};

// Perspective camera
struct Camera
{
    Camera();

    simd_float4x4 view;
    simd_float4x4 projection;
};

struct Scene
{
    Camera camera;
    Triangle t1;
};
