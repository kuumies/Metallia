#pragma once

#include <array>
#include <stdint.h>
#include <simd/simd.h>
#include <vector>

// Defines geometry and topology of rendered object
class Mesh
{
public:
    // Defines the primitive type
    enum class PrimitiveType
    {
        Triangle
    };

    // Defines the vertex attributes
    enum Attributes
    {
        Position = 0x01,
        Color    = 0x02,
    };

    PrimitiveType primitiveType{PrimitiveType::Triangle};
    int attributes = Attributes::Position | Attributes::Color;
    std::vector<float> vertexData;
    std::vector<unsigned> indexData;
};

// Defines a rendered object
class Model
{
public:
    // Constructs the model from geometry
    // Initial transform is an identity
    Model();
    Model(const std::vector<Mesh>& meshes);

    // Updates the model's TRS transform.
    void updateTransform();

    // One or more geometries
    std::vector<Mesh> meshes;

    // Transform is composed of position, rotation and scale
    simd_float3 position;
    simd_quatf rotation;
    simd_float3 scale;
    simd_float4x4 transform;
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
    Model m;
};
