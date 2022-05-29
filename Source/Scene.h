#pragma once

#import <Metal/Metal.h>
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

    // Vertex front face winding order
    enum class Winding
    {
        Clockwise,
        CounterClockwise
    };

    // Face culling
    enum class Culling
    {
        None,
        Front,
        Back
    };

    // Defines the vertex attributes
    enum Attributes
    {
        Position = 0x01,
        Color    = 0x02,
    };

    PrimitiveType primitiveType{PrimitiveType::Triangle};
    Winding winding{Winding::CounterClockwise};
    Culling culling{Culling::Back};
    int attributes = Attributes::Position | Attributes::Color;
    bool useIndices{true};
    std::vector<float> vertexData;
    std::vector<unsigned> indexData;
    id<MTLBuffer> vertexBuffer;
    id<MTLBuffer> indexBuffer;
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

    void updateView();
    void updateProjection();

    simd_float3 position;
    simd_quatf rotation;
    simd_float4x4 view;

    float fovY{45.0f};
    float aspect{1.0f};
    float zNear{0.1f};
    float zFar{150.0f};
    simd_float4x4 projection;
};

struct Scene
{
    Camera camera;
    Model m;
};
