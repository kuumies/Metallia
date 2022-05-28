#pragma once

#include <array>
#include <stdint.h>
#include <simd/simd.h>

struct Vertex
{
    float position[3];
    unsigned char color[4];
};

struct Triangle
{
    std::array<Vertex, 3> vertices;

    simd::float4x4 transform;

    void updateRotationAnimation(float angleRad);
};

struct Scene
{
    Triangle t1;
};
