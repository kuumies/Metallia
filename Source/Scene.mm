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
    : view(translate(0.0f, 0.0f, -2.0f))
    , projection(perspective(45.0f * M_PI/180.0f, 1.0f, 0.1f, 150.0f))
{}
