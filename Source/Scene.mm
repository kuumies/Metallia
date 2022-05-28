#include "Scene.h"
#include <cmath>
#include <cstring>
#include "Math.h"

void Triangle::updateRotationAnimation(float angleRad)
{
    float sin = std::sin(angleRad);
    float cos = std::cos(angleRad);

    transform = matrix_identity_float4x4;
    transform.columns[0][0] = cos;
    transform.columns[0][1] = -sin;
    transform.columns[1][0] = sin;
    transform.columns[1][1] = cos;
}

Camera::Camera()
    : view(translate(0.0f, 0.0f, -2.0f))
    , projection(perspective(45.0f * M_PI/180.0f, 1.0f, 0.1f, 150.0f))
{}

Triangle::Triangle()
    : transform(matrix_identity_float4x4)
{}
