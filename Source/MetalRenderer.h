#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include "Scene.h"

// Incase of an error renderer will log the error and exit the app
@interface MetalRenderer : NSObject

- (id) initWithFrame: (NSRect) frameRect
              device: (id<MTLDevice>) device
         sampleCount: (NSUInteger) sampleCount
               scene: (Scene*) scene;

- (void) renderWithFrame: (NSRect) screenRect
    renderPassDescriptor: (MTLRenderPassDescriptor*) renderPassDescriptor
                drawable: (id<CAMetalDrawable>) drawable
                   scene: (Scene*) scene;
@end
