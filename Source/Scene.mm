#include "Scene.h"
#include <cmath>
#include <cstring>

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
