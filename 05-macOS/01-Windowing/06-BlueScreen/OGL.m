
// import statement (include + pragma once)
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <QuartzCore/CVDisplayLink.h>    // CV - Core Video
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>


// Global Function Declarations
CVReturn MyDisplayLinkCallback(CVDisplayLinkRef, const CVTimeStamp*, const CVTimeStamp*, CVOptionFlags, CVOptionFlags*, void*);


// Global Variable declarations
FILE *gFile = NULL;


// in AppDelegate.h & import
@interface AppDelegate:NSObject <NSApplicationDelegate,NSWindowDelegate>
@end


// in View.h & import
@interface GLView:NSOpenGLView 
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
    GLView *glView;
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // Code

    // Log file open code
    NSBundle *appBundle = [NSBundle mainBundle];
    NSString *appDirPath = [appBundle bundlePath];
    NSString *parentDirPath = [appDirPath stringByDeletingLastPathComponent];
    NSString *logFileNameWithPath = [NSString stringWithFormat:@"%@/log.txt",parentDirPath];
    const char *pszLogFileNameWithPath = [logFileNameWithPath cStringUsingEncoding:NSASCIIStringEncoding];
    gFile = fopen(pszLogFileNameWithPath, "w");
    if(gFile == NULL)
    {
        NSLog(@"Log File can not be created!\n");
        [self release];
        [NSApp terminate:self];
    }
    fprintf(gFile, "Program Started Successfully.\n");

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

    // Painting window background black
    [window setBackgroundColor:[NSColor blackColor]];

    // create our view
    glView = [[GLView alloc]initWithFrame:win_rect];

    // set our view as view of our of window
    [window setContentView:glView];

    // set delegate for our window
    [window setDelegate:self];

    // show the window, give it's keyboard focus & make it top on zorder
    [window makeKeyAndOrderFront:self];
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    // Code

    // Log File close code
    if(gFile)
    {
        fprintf(gFile, "Program Finished Successfully.\n");
        fclose(gFile);
        gFile = NULL;
    } 

}

-(void)windowWillClose:(NSNotification *)notification
{
    // Code
    [NSApp terminate:self];
}

-(void)dealloc
{
    [super dealloc];
    [glView release];
    [window release];
}
@end



// implementation of our View interface 
@implementation GLView
{
    CVDisplayLinkRef displayLink;
}

-(id)initWithFrame:(NSRect)frame
{
    // Code
    self = [super initWithFrame:frame];
    if(self)
    {
        // Step 1 : Declare OpenGL Attributes
        NSOpenGLPixelFormatAttribute attributes[] = 
        {
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core,
            NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFANoRecovery, 
            NSOpenGLPFAAccelerated, 
            NSOpenGLPFADoubleBuffer, 
            0
        };

        // Step 2 : Create OpenGL Pixel format using above attributes.
        NSOpenGLPixelFormat *pixelFormat = [[[NSOpenGLPixelFormat alloc]initWithAttributes:attributes] autorelease];
        if(pixelFormat == nil)
        {
            fprintf(gFile, "Creating Pixel Format Failed.\n");
            
            [self uninitialize];
            [self release];
            [NSApp terminate:self];
        }

        // Step 3 : Create OpenGL Context above created Pixel format.
        NSOpenGLContext *glContext = [[[NSOpenGLContext alloc]initWithFormat:pixelFormat shareContext:nil] autorelease];
        if(glContext == nil)
        {
            fprintf(gFile, "Creating OpenGL Context Failed.\n");
            
            [self uninitialize];
            [self release];
            [NSApp terminate:self];
        }

        // Step 4 : Set Pixel format.
        [self setPixelFormat:pixelFormat];
        
        // Step 5 : Set Context format.
        [self setOpenGLContext:glContext];
    }

    return(self);
}

-(void)prepareOpenGL
{
    // Code
    [super prepareOpenGL];
    
    [[self openGLContext] makeCurrentContext];

    // Matching monitor retracing with the double buffer swapping
    GLint swapInterval = 1;

    [[self openGLContext]setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];


    int result = [self initialize];


    // Create and start display link

    // Step 1 : Create display link according to the current active display
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);

    // Step 2 : Set the callback method for OpenGL thread
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self); 
    
    // Step 3 : Convert NSOpenGLPixelFormat to CGLPixelFormat
    CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];

    // Step 4 : Convert NSOpenGLContext to CGLContext
    CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];

    // Step 5 : Set above two for display link
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    
    // Step 6 : Start the display link (start OpenGL thread)
    CVDisplayLinkStart(displayLink);
}

-(void)reshape
{
    // Code
    [super reshape];

    [[self openGLContext] makeCurrentContext];

    CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);

    NSRect rect = [self bounds];
    
    GLint width = rect.size.width;
    GLint height = rect.size.height;

    // resize
    [self resize:width :height];

    CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}

-(void)drawRect:(NSRect)dirtyRect
{
    // Code

    // Call rendering function here too to avoid flickering.
    [self drawView];
}

// Our Rendering function
-(void)drawView
{
    // Code
    [[self openGLContext] makeCurrentContext];

    CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);

    [self display];

    CGLFlushDrawable((CGLContextObj)[[self openGLContext] CGLContextObj]);

    CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}

// Function called per frame using auto release pool
-(CVReturn)getFrameForTime:(const CVTimeStamp*) outputTime
{
    // Code

    // create Auto release pool for memory management
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    [self drawView];
    [self myupdate];

    // Auto Release all pending objects in our application 
    [pool release];

    return(kCVReturnSuccess);
}

-(int)initialize
{
    // Code

    [self printGLInfo];

    // Enabling Depth
	glClearDepth(1.0f);					// Clears Depth Buffer in FrameBuffer (make all bits 1)
	glEnable(GL_DEPTH_TEST);			// Enables Rasterizer's Depth Test (1 of the 8 tests)
	glDepthFunc(GL_LEQUAL);				// Depth Comparing/Testing Function (GL_LEQUAL - Less than or equal to 1.0f given in glClearDepth(1.0f))

    // Set the Clear Color of Window to Blue (OpenGL Function)
	glClearColor(0.0f, 0.0f, 1.0f, 1.0f);

    return(0);
}

-(void)printGLInfo
{
    // Code

    fprintf(gFile, "OpenGL Vendor : %s.\n", glGetString(GL_VENDOR));
	fprintf(gFile, "OpenGL Renderer : %s.\n", glGetString(GL_RENDERER));
	fprintf(gFile, "OpenGL Version : %s.\n", glGetString(GL_VERSION));
	fprintf(gFile, "OpenGL Shading Language(GLSL) Version : %s.\n", glGetString(GL_SHADING_LANGUAGE_VERSION));
}

-(void)resize:(int)width :(int)height
{
    // Code
    if (height <= 0)
		height = 1;

	glViewport(0, 0, (GLsizei)width, (GLsizei)height);					// Like Binacular (Part of window to view)
}

-(void)display
{
    // Code
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);	

}

-(void)myupdate
{
    // Code

}

-(void)uninitialize
{
    // Code

}

-(BOOL)acceptsFirstResponder
{
    // Code
    [[self window] makeFirstResponder:self];
    return(YES);
}

-(void)keyDown:(NSEvent *)event
{
    // Code
    int key = (int)[[event characters] characterAtIndex:0];

    switch(key)
    {
        case 27:
            [self uninitialize];
            [self release];
            [NSApp terminate:self];
            break;

        case 'F':
        case 'f':
            [[self window] toggleFullScreen:self];
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

    [self uninitialize];

    if(displayLink) 
    {
        CVDisplayLinkStop(displayLink);
        CVDisplayLinkRelease(displayLink);
        displayLink = nil;
    }
}
@end



// Definition of global callback function  
CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext)
{
    // Code
    CVReturn result = [(GLView*)displayLinkContext getFrameForTime:outputTime];
    return(result);
}



