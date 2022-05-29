#import "MetalView.h"
#import "MetalRenderer.h"

@implementation KFIMetalView
{
    MetalRenderer* renderer;
    Scene scene;
    int frame;
}

- (id) initWithFrame: (NSRect) frameRect
{
    // -------------------------------------------------------------------------
    // Create the metal device

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device)
    {
        NSLog(@"Failed to create metal device");
        return nil;
    }

    frame = 0;

    // -------------------------------------------------------------------------
    // Initialize MTKView

    self = [super initWithFrame: frameRect device: device];
    if (!self)
        return nil;

    Mesh triMesh;
    triMesh.vertexData = {
        -0.5f, -0.5f, 0.0f,  1.0f, 1.0f, 1.0f, 1.0f,
         0.5f, -0.5f, 0.0f,  0,    1.0f, 0,    1.0f,
         0.0f,  0.5f, 0.0f,  0,    0,    1.0f, 1.0f
    };
    triMesh.indexData = { 0, 1, 2 };

    Model triModel;
    triModel.meshes.push_back(triMesh);

    scene.models.push_back(triModel);
    scene.models.push_back(triModel);

    // -------------------------------------------------------------------------
    // Initialize renderer

    renderer = [[[MetalRenderer alloc]
            initWithFrame: frameRect
                   device: device
              sampleCount: self.sampleCount
                    scene: &scene] autorelease];

    return self;
}

- (void) drawRect: (CGRect) rect
{
    frame++;

    scene.models[0].position = simd_float3{0.2f, 0.0f, 0.0f};
    scene.models[0].scale = simd_float3{1.1f, 1.1f, 1.1f};
    scene.models[0].rotation = simd_quaternion(float(frame * 0.01f), simd_float3{0.0f, 0.0f, 1.0f});
    scene.models[0].updateTransform();

    scene.models[1].position = simd_float3{-0.2f, -0.0f, 0.1f};
    scene.models[0].scale = simd_float3{0.9f, 0.9f, 0.9f};
    scene.models[1].rotation = simd_quaternion(-float(frame * 0.01f), simd_float3{0.0f, 0.0f, 1.0f});
    scene.models[1].updateTransform();

    const NSRect viewport =
        NSMakeRect(0, 0, self.drawableSize.width, self.drawableSize.height);

    [renderer renderWithFrame: viewport
         renderPassDescriptor: self.currentRenderPassDescriptor
                     drawable: self.currentDrawable
                        scene: &scene];

    [super drawRect:rect];
}

-(void) windowWillClose: (NSNotification*) notification
{
    [NSApp terminate:self];
}

@end
