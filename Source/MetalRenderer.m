#import "MetalRenderer.h"
#include <array>
#include "Common.h"
#include "Math.h"
#include "Scene.h"

@implementation MetalRenderer

    // Color and depth+stencil pixel formats are constants
    constexpr MTLPixelFormat c_colorPixelFormat =
        MTLPixelFormatBGRA8Unorm;
    constexpr MTLPixelFormat c_depthStencilPixelFormat =
        MTLPixelFormatDepth32Float_Stencil8;

    // Metallib must match the one defined in cmake.
    // TODO: CMake should generate a header with the lib name
    NSString* const c_metallibName = @"Shaders.metal.metallib";

    // Pipeline states
    id<MTLDepthStencilState> depthStencilState;
    id<MTLRenderPipelineState> pipelineState;

    // Uniform buffer sync
    int uniformBufferIndex;
    dispatch_semaphore_t uniformSemaphore;

    // Command queue
    id<MTLCommandQueue> commandQueue;


- (id) initWithFrame: (NSRect) frameRect
              device: (id<MTLDevice>) device
         sampleCount: (NSUInteger) sampleCount
               scene: (Scene*) scene
{
    self = [super init];
    if (!self) return nil;

    // -------------------------------------------------------------------------
    // Pipeline - Load vertex and fragment shader functions from shader library
    // Remember that they are loaded from bundle!

    NSError* error = nil;
    id<MTLLibrary> shaderLibrary = [device newLibraryWithFile: c_metallibName
                                                        error: &error];
    if (!shaderLibrary)
    {
        NSLog(@"Failed to load shader library %@: %@", c_metallibName, error);
        exit(0);
    }

    id<MTLFunction> vertFunction = [shaderLibrary newFunctionWithName:@"vert"];
    id<MTLFunction> fragFunction = [shaderLibrary newFunctionWithName:@"frag"];

    // -------------------------------------------------------------------------
    // Pipeline
    // Create depth/stencil state

    MTLDepthStencilDescriptor* depthStencilDescriptor =
        [[[MTLDepthStencilDescriptor alloc] init] autorelease];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDescriptor.depthWriteEnabled = YES;

    depthStencilState =
        [device newDepthStencilStateWithDescriptor: depthStencilDescriptor];

    // -------------------------------------------------------------------------
    // Pipeline
    // Vertex descriptor

    MTLVertexDescriptor* vertexDescriptor =
        [[[MTLVertexDescriptor alloc] init] autorelease];

    MTLVertexAttributeDescriptor* position =
        vertexDescriptor.attributes[VertexAttributeIndex::Position];
    position.format = MTLVertexFormatFloat3;
    position.offset = 0;
    position.bufferIndex = MeshVertexBuffer;

    MTLVertexAttributeDescriptor* color =
        vertexDescriptor.attributes[VertexAttributeIndex::Color];
    color.format = MTLVertexFormatFloat4;
    color.offset = 3 * sizeof(float);
    color.bufferIndex = MeshVertexBuffer;

    MTLVertexBufferLayoutDescriptor* vertexBufferLayout =
        vertexDescriptor.layouts[MeshVertexBuffer];
    vertexBufferLayout.stride = 7 * sizeof(float);
    vertexBufferLayout.stepRate = 1;
    vertexBufferLayout.stepFunction = MTLVertexStepFunctionPerVertex;

    // -------------------------------------------------------------------------
    // Pipeline
    // Pipeline state

    MTLRenderPipelineDescriptor* pipelineDescriptor =
        [[[MTLRenderPipelineDescriptor alloc] init] autorelease];
    pipelineDescriptor.sampleCount = sampleCount;
    pipelineDescriptor.vertexFunction = vertFunction;
    pipelineDescriptor.fragmentFunction = fragFunction;
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    pipelineDescriptor.colorAttachments[0].pixelFormat = c_colorPixelFormat;
    pipelineDescriptor.depthAttachmentPixelFormat = c_depthStencilPixelFormat;
    pipelineDescriptor.stencilAttachmentPixelFormat = c_depthStencilPixelFormat;

    pipelineState =
        [device newRenderPipelineStateWithDescriptor: pipelineDescriptor
                                               error: &error];
    if (!pipelineState)
    {
        NSLog(@"Failed to create render pipeline state due %@", error);
        exit(0);
    }

    // -------------------------------------------------------------------------
    // Mesh buffers

    for (Model& model : scene->models)
    {
        for (Mesh& mesh : model.meshes)
        {
            mesh.vertexBuffer =
                [device newBufferWithBytes: mesh.vertexData.data()
                                    length: mesh.vertexData.size() * sizeof(float)
                                   options: MTLResourceStorageModePrivate];

            mesh.indexBuffer =
                [device newBufferWithBytes: mesh.indexData.data()
                                    length: mesh.indexData.size() * sizeof(unsigned)
                                   options: MTLResourceStorageModePrivate];

            for (int ubIndex = 0; ubIndex < Mesh::c_uniformBufferCount; ++ubIndex)
            {
                mesh.uniformBuffers[ubIndex] =
                    [device newBufferWithLength: sizeof(Uniforms)
                                        options: MTLResourceCPUCacheModeWriteCombined];
            }
        }
    }

    // -------------------------------------------------------------------------
    // Uniform buffer sync

    uniformBufferIndex = 0;
    uniformSemaphore = dispatch_semaphore_create(Mesh::c_uniformBufferCount);

    // -------------------------------------------------------------------------
    // Command queue

    commandQueue = [[device newCommandQueue] autorelease];

    return self;
}


- (void) renderWithFrame: (NSRect) screenRect
    renderPassDescriptor: (MTLRenderPassDescriptor*) renderPassDescriptor
                drawable: (id<CAMetalDrawable>) drawable
                   scene: (Scene*) scene;
{
    // -------------------------------------------------------------------------
    // Uniform buffer access synchronization
    // Wait for uniform semaphore to become available

    dispatch_semaphore_wait(uniformSemaphore, DISPATCH_TIME_FOREVER);

    uniformBufferIndex = (uniformBufferIndex + 1) % Mesh::c_uniformBufferCount;

    // -------------------------------------------------------------------------
    // Command buffer

    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    // -------------------------------------------------------------------------
    // Render command Encoder

    id<MTLRenderCommandEncoder> encoder =
        [commandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];

    // Viewport
    const MTLViewport viewport = {
        screenRect.origin.x, screenRect.origin.y,
        screenRect.size.width, screenRect.size.height,
        0.0, 1.0 };
    [encoder setViewport: viewport];

    // States
    [encoder setDepthStencilState: depthStencilState];
    [encoder setRenderPipelineState: pipelineState];

    for (Model& m : scene->models)
    {
        const simd_float4x4 model = m.transform;
        const simd_float4x4 view = scene->camera.view;
        const simd_float4x4 proj = scene->camera.projection;

        for (Mesh& mesh : m.meshes)
        {
            Uniforms* uniforms =
                (Uniforms*) [mesh.uniformBuffers[uniformBufferIndex] contents];

            uniforms->projectionViewModel =
                matrix_multiply(proj, matrix_multiply(view, model));

            // Uniform buffer
            [encoder setVertexBuffer: mesh.uniformBuffers[uniformBufferIndex]
                              offset: 0
                             atIndex: FrameUniformBuffer];

            // Front face winding
            MTLWinding mtlWinding;
            switch(mesh.winding)
            {
                case Mesh::Winding::Clockwise:
                    mtlWinding = MTLWindingClockwise;
                    break;

                case Mesh::Winding::CounterClockwise:
                    mtlWinding = MTLWindingCounterClockwise;
                    break;
            }
            [encoder setFrontFacingWinding: mtlWinding];

            // Face culling
            MTLCullMode mtlCulling;
            switch(mesh.culling)
            {
                case Mesh::Culling::None:  mtlCulling = MTLCullModeNone;  break;
                case Mesh::Culling::Back:  mtlCulling = MTLCullModeBack;  break;
                case Mesh::Culling::Front: mtlCulling = MTLCullModeFront; break;
            }

            [encoder setCullMode: mtlCulling];

            // Vertex buffer
            [encoder setVertexBuffer: mesh.vertexBuffer
                              offset: 0
                             atIndex: MeshVertexBuffer];

            // primitive
            MTLPrimitiveType mtlPrimitiveType;
            switch(mesh.primitiveType)
            {
                case Mesh::PrimitiveType::Triangle:
                    mtlPrimitiveType = MTLPrimitiveTypeTriangle;
                    break;
            }

            // Draw
            if (mesh.useIndices)
            {
                NSUInteger indexCount = [mesh.indexBuffer length] / sizeof(unsigned);
                [encoder drawIndexedPrimitives: mtlPrimitiveType
                                    indexCount: indexCount
                                     indexType: MTLIndexTypeUInt32
                                   indexBuffer: mesh.indexBuffer
                             indexBufferOffset: 0];
            }
            else
            {
                [encoder drawPrimitives: mtlPrimitiveType
                            vertexStart: 0
                            vertexCount: [mesh.vertexBuffer length]];
            }
        }
    }

    [encoder endEncoding];

    // -------------------------------------------------------------------------
    // When GPU finishes executing commands the semaphore is signaled
    // The semaphore is shared with the block lambda.

    __block dispatch_semaphore_t blockSemaphore = uniformSemaphore;

    MTLCommandBufferHandler completedHandler = ^(id<MTLCommandBuffer> cb)
    { dispatch_semaphore_signal(blockSemaphore); };

    [commandBuffer addCompletedHandler: completedHandler];

    // -------------------------------------------------------------------------
    // Drawing to user provided drawable

    [commandBuffer presentDrawable: drawable];
    [commandBuffer commit];
}

@end
