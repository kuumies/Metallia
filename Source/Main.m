#import <Cocoa/Cocoa.h>
#import "MetalView.h"

int main(int argc, const char* argv[])
{
    // -------------------------------------------------------------------------
    // Autorelease Pool

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    // -------------------------------------------------------------------------
    // Application

    NSApplication* app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    [app activateIgnoringOtherApps: YES];

    // -------------------------------------------------------------------------
    // Menu

    NSString* processName = [[NSProcessInfo processInfo] processName];
    NSString* quitMenuString = [[NSString alloc] initWithString: @"Quit "];
    [quitMenuString autorelease];
    quitMenuString = [quitMenuString stringByAppendingString: processName];

    NSMenuItem* quitMenuItem = [NSMenuItem alloc];
    [quitMenuItem setTitle: quitMenuString];
    [quitMenuItem setTarget: app];
    [quitMenuItem setAction: @selector(terminate:)];
    [quitMenuItem setKeyEquivalentModifierMask: NSCommandKeyMask];
    [quitMenuItem setKeyEquivalent: @"q"];
    [quitMenuItem autorelease];

    NSMenu* appMenu = [[NSMenu new] autorelease];
    [appMenu addItem: quitMenuItem];

    NSMenuItem* mainMenuItem = [[NSMenuItem new] autorelease];
    [mainMenuItem setSubmenu: appMenu];

    NSMenu* mainMenu = [[NSMenu new] autorelease];
    [mainMenu addItem: mainMenuItem];
    [app setMainMenu: mainMenu];

    // -------------------------------------------------------------------------
    // View

    NSRect viewRect = NSMakeRect(0, 0, 720, 576);
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSRect windowRect = NSMakeRect(
        NSMidX(screenRect) - NSMidX(viewRect),
        NSMidY(screenRect) - NSMidY(viewRect),
        viewRect.size.width,
        viewRect.size.height);

    KFIMetalView* view = [KFIMetalView alloc];
    view = [view initWithFrame: windowRect];
    [view autorelease];

    // -------------------------------------------------------------------------
    // Window

    NSUInteger windowFlags =
            NSWindowStyleMaskClosable |
            NSWindowStyleMaskResizable |
            NSWindowStyleMaskTitled |
            NSWindowStyleMaskMiniaturizable;

    NSWindow* window = [NSWindow alloc];
    [window initWithContentRect: windowRect
                      styleMask: windowFlags
                        backing: NSBackingStoreBuffered
                          defer: NO];
    [window setTitle:processName];
    [window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
    [window orderFrontRegardless];
    [window setLevel: NSNormalWindowLevel];
    [window makeKeyAndOrderFront: window];
    [window autorelease];
    [window setContentView: view];
    [window setDelegate: view];

    // Window controller
    NSWindowController * windowController =
        [[NSWindowController alloc] initWithWindow: window];
    [windowController autorelease];

    [app run];

    [pool drain];

    return EXIT_SUCCESS;
}
