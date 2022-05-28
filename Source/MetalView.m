#import "MetalView.h"
#import "MetalRenderer.h"

@implementation KFIMetalView
{
    MetalRenderer* renderer;
    Scene scene;
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

    // -------------------------------------------------------------------------
    // Initialize MTKView

    self = [super initWithFrame:frameRect device:device];
    if (!self)
        return nil;

    scene.t1.vertices =
    {
        Vertex{ { -0.5f, -0.5f, 0.0f }, {255,   255,   255,  255 } },
        Vertex{ { -0.0f,  0.5f, 0.0f }, {  0,   255,     0,  255 } },
        Vertex{ {  0.5f, -0.5f, 0.0f }, {  0,      0,  255,  255 } },
    };
    scene.t1.updateRotationAnimation(0.0f);

    // -------------------------------------------------------------------------
    // Initialize renderer

    renderer = [[[MetalRenderer alloc]
            initWithFrame:frameRect
                   device:device
              sampleCount:self.sampleCount
                    scene:scene] autorelease];

    return self;
}

- (void) drawRect: (CGRect) rect
{
    const NSRect viewport =
        NSMakeRect(0, 0, self.drawableSize.width, self.drawableSize.height);


    [renderer render:viewport
        renderPassDescriptor:self.currentRenderPassDescriptor
                    drawable:self.currentDrawable
                       scene:scene];

    [super drawRect:rect];
}

-(void) windowWillClose: (NSNotification*) notification
{
    [NSApp terminate:self];
}

@end
