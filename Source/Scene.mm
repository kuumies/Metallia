#include "Scene.h"
#include <cmath>
#include <cstring>
#include "Math.h"

Model::Model()
    : Model(std::vector<Mesh>())
{}

Model::Model(const std::vector<Mesh>& meshes)
    : meshes(meshes)
    , position{0, 0, 0}
    , rotation(simd_quaternion(0.0f, 0.0f, 0.0f, 1.0f))
    , scale{1, 1, 1}
{
    updateTransform();
}

void Model::updateTransform()
{
    transform = trs(position, rotation, scale);
}

Camera::Camera()
    : position{0.0f, 0.0f, 2.0f}
    , rotation(simd_quaternion(0.0f, 0.0f, 0.0f, 1.0f))
{
    updateView();
    updateProjection();
}

void Camera::updateView()
{
    simd_float4x4 m = matrix_identity_float4x4;
    m = translate(position);
    m = matrix_multiply(simd_matrix4x4(rotation), m);
    view = simd_inverse(m);
}

void Camera::updateProjection()
{
    projection = perspective(fovY * M_PI / 180.0f, aspect, zNear, zFar);
}
