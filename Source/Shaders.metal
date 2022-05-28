#include <simd/simd.h>
#include "Common.h"

using namespace metal;

struct VertexInput
{
    float3 position [[attribute(VertexAttributeIndex::Position)]];
    half4 color [[attribute(VertexAttributeIndex::Color)]];
};

struct ShaderInOut
{
    float4 position [[position]];
    half4  color;
};

vertex ShaderInOut vert(
    VertexInput in [[stage_in]],
    constant Uniforms& uniforms [[buffer(BufferIndex::FrameUniformBuffer)]])
{
    float4 pos4 = float4(in.position, 1.0);

    ShaderInOut out;
    out.position = uniforms.projectionViewModel * pos4;
    out.color = in.color / 255.0;

    return out;
}

fragment half4 frag(ShaderInOut in [[stage_in]])
{
    return in.color;
}
