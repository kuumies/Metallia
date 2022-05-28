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

    // Buffers
    id<MTLBuffer> vertexBuffer;

    // Uniform buffers
    constexpr int c_uniformBufferCount = 3;
    std::array<id<MTLBuffer>, c_uniformBufferCount> uniformBuffers;
    int uniformBufferIndex;

    // Sync
    dispatch_semaphore_t uniformSemaphore;

    // Command queue
    id<MTLCommandQueue> commandQueue;

- (id) initWithFrame: (NSRect) frameRect
              device: (id<MTLDevice>) device
         sampleCount: (NSUInteger) sampleCount
               scene: (Scene) scene
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
        [device newDepthStencilStateWithDescriptor:depthStencilDescriptor];

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
    color.format = MTLVertexFormatUChar4;
    color.offset = sizeof(Vertex::position);
    color.bufferIndex = MeshVertexBuffer;

    MTLVertexBufferLayoutDescriptor* vertexBufferLayout =
        vertexDescriptor.layouts[MeshVertexBuffer];
    vertexBufferLayout.stride = sizeof(Vertex);
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
    // Triangle vertex buffer

    vertexBuffer = [device newBufferWithBytes: scene.t1.vertices.data()
                                       length: sizeof(scene.t1.vertices)
                                      options: MTLResourceStorageModePrivate];

    // -------------------------------------------------------------------------
    // Uniforms

    // Buffers
    for (int ubIndex = 0; ubIndex < c_uniformBufferCount; ++ubIndex)
    {
        uniformBuffers[ubIndex] =
            [device newBufferWithLength: sizeof(Uniforms)
                                options: MTLResourceCPUCacheModeWriteCombined];
    }

    // Current buffer index
    uniformBufferIndex = 0;

    // Sync for buffers, starts signaled
    uniformSemaphore = dispatch_semaphore_create(c_uniformBufferCount);

    // -------------------------------------------------------------------------
    // Command queue

    commandQueue = [[device newCommandQueue] autorelease];

    return self;
}

- (void) render: (NSRect) screenRect
    renderPassDescriptor: (MTLRenderPassDescriptor*) renderPassDescriptor
                drawable: (id<CAMetalDrawable>) drawable
                   scene: (Scene) scene;
{
    // -------------------------------------------------------------------------
    // Uniform buffer access synchronization
    // Wait for one of the uniform semaphore to become available

    dispatch_semaphore_wait(uniformSemaphore, DISPATCH_TIME_FOREVER);

    uniformBufferIndex = (uniformBufferIndex + 1) % c_uniformBufferCount;
    Uniforms* uniforms =
        (Uniforms*) [uniformBuffers[uniformBufferIndex] contents];

    const simd_float4x4 model = scene.t1.transform;
    const simd_float4x4 view = scene.camera.view;
    const simd_float4x4 proj = scene.camera.projection;

    uniforms->projectionViewModel =
        matrix_multiply(proj, matrix_multiply(view, model));

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

    // Uniform buffer
    [encoder setVertexBuffer: uniformBuffers[uniformBufferIndex]
             offset: 0
             atIndex: FrameUniformBuffer];

    // Vertex buffer
    [encoder setVertexBuffer: vertexBuffer
             offset: 0
             atIndex: MeshVertexBuffer];

    // Draw triangle
    [encoder drawPrimitives: MTLPrimitiveTypeTriangle
             vertexStart: 0
             vertexCount: 3];

    // Done
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
