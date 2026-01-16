
// import statement (include + pragma once)
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


// in AppDelegate.h & import
@interface AppDelegate:NSObject <NSApplicationDelegate,NSWindowDelegate>
@end


// in View.h & import
@interface View:NSView 
@end


// main function 
int main(int argc, char *argv[])
{
    // Code

    // create Auto release pool for memory management
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

    // create global, shared NSApp Application Object
    NSApp = [NSApplication sharedApplication];

    // Set it's delegate to our own AppDelegate
    [NSApp setDelegate:[[AppDelegate alloc]init] ];

    // Start Message/Run loop
    [NSApp run];

    // Auto Release all pending objects in our application 
    [pool release];

    return(0);
}


// implementation of Our Own AppDelegate
@implementation AppDelegate
{
    NSWindow *window;
    View *view;
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // Code

    // Declare Rectangle for frame of our window
    NSRect win_rect = NSMakeRect(0.0, 0.0, 800.0, 600.0);  

    // Create the Window 
    window = [[NSWindow alloc]initWithContentRect:win_rect 
                                        styleMask:NSWindowStyleMaskTitled | 
                                                  NSWindowStyleMaskClosable | 
                                                  NSWindowStyleMaskMiniaturizable |
                                                  NSWindowStyleMaskResizable 
                                          backing:NSBackingStoreBuffered
                                            defer:NO];

    // Give title to the window
    [window setTitle:@"PNV: Cocoa Window"];

    // Center the window
    [window center];

    // create our view
    view = [[View alloc]initWithFrame:win_rect];

    // set our view as view of our of window
    [window setContentView:view];

    // set delegate for our window
    [window setDelegate:self];

    // show the window, give it's keyboard focus & make it top on zorder
    [window makeKeyAndOrderFront:self];
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    // Code
}

-(void)windowWillClose:(NSNotification *)notification
{
    // Code
    [NSApp terminate:self];
}

-(void)dealloc
{
    [super dealloc];
    [view release];
    [window release];
}
@end



// implementation of our View interface 
@implementation View

-(id)initWithFrame:(NSRect)frame
{
    // Code
    self = [super initWithFrame:frame];

    return(self);
}

-(void)drawRect:(NSRect)dirtyRect
{
    // Code

    // Declare background color black
    NSColor *bgColor = [NSColor blackColor];

    // Set this color
    [bgColor set];

    // Fill the window rectangle with above black color
    NSRectFill(dirtyRect);
}

-(BOOL)acceptsFirstResponder
{
    // Code
    [[self window]makeFirstResponder:self];
    return(YES);
}

-(void)keyDown:(NSEvent *)event
{
    // Code
    int key = (int)[[event characters]characterAtIndex:0];

    switch(key)
    {
        case 27:
            [self release];
            [NSApp terminate:self];
            break;

        case 'F':
        case 'f':
            [[self window]toggleFullScreen:self];
            break;

        default:
            break;
    }
}

-(void)mouseDown:(NSEvent *)event
{
    // Code

}

-(void)rightMouseDown:(NSEvent *)event
{
    // Code

}

-(void)dealloc
{
    // Code
    [super dealloc];
}
@end
