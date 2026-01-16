#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <QuartzCore/CVDisplayLink.h>                            // Core Video Display Link
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "vmath.h"
using   namespace vmath;

#define WIN_WIDTH   800.0
#define WIN_HEIGHT  600.0

// Global Function Declarations
CVReturn MyDisplayLinkCallback(CVDisplayLinkRef, const CVTimeStamp *, const CVTimeStamp *, CVOptionFlags, CVOptionFlags *, void *);

// Global Variable Declarations
FILE* gpFile_AMC = NULL;

enum
{
	AMC_ATTRIBUTE_POSITION = 0,
	AMC_ATTRIBUTE_COLOR
};


@interface AppDelegate:NSObject<NSApplicationDelegate, NSWindowDelegate>
@end

@interface GLView:NSOpenGLView
@end

// Main Function
int main(int argc, char* argv[])
{
    // --------------------------------------------------- CODE -----------------------------------------------------------------------
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];  // Create AutoreleasePool For Memory Management
    NSApp = [NSApplication sharedApplication];                  // Global Shared NS APP Object
    [NSApp setDelegate:[[AppDelegate alloc]init]];              // Set It's Delegate To Our Own Custom App Delegate
    [NSApp run];                                                // Start NS APP Run Loop
    [pool release];                                             // Let Auto Release Pool, Release All Pending Object In Our Application

    return(0);
}

// Implementation Of Our Custom App Delegate Interface
@implementation AppDelegate
{
    NSWindow *window;
    GLView *glView_AMC;
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification                     // Like WM_CREATE In Windows
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

    // Log File Opening Code
    NSBundle *appBundle_AMC = [NSBundle mainBundle];
    NSString *appDirPath_AMC = [appBundle_AMC bundlePath];
    NSString *parentDirPath_AMC = [appDirPath_AMC stringByDeletingLastPathComponent];
    NSString *logFileNameWithPath_AMC = [NSString stringWithFormat:@"%@/Log.txt",parentDirPath_AMC];
    
    const char* pszLogFileNameWithPath_AMC = [logFileNameWithPath_AMC cStringUsingEncoding:NSASCIIStringEncoding];
    
    gpFile_AMC = fopen(pszLogFileNameWithPath_AMC, "w");
    
    if(gpFile_AMC == NULL)
    {
        NSLog(@"Log File Can Not Be Created !!!\n");
        [self release];
        [NSApp terminate:self];
    }
    else
    {
        fprintf(gpFile_AMC, "=============== ** Program Started Successfully  !!! ** ===============\n\n");
    }
    
    // Declare Rectangle For Frame/Border Of Our Window
    NSRect winRect = NSMakeRect(0.0, 0.0, WIN_WIDTH, WIN_HEIGHT);

    // Create the window
    window = [[NSWindow alloc]initWithContentRect:winRect
                                        styleMask:NSWindowStyleMaskTitled |             // WS_CAPTION
                                                  NSWindowStyleMaskClosable |
                                                  NSWindowStyleMaskMiniaturizable |     // WS_MINIMIZEBOX
                                                  NSWindowStyleMaskResizable            // WS_HREDRAW|WS_VREDRAW
                                          backing:NSBackingStoreBuffered
                                            defer:NO];

    [window setTitle: @"pnv : Cocoa Window"];               // Give Title To The Window
    [window center];                                        // Center The Window
    [window setBackgroundColor:[NSColor blackColor]];       // Painting Window Background As Black
    glView_AMC = [[GLView alloc]initWithFrame: winRect];    // Create The Custom View
    [window setContentView: glView_AMC];                    // Set This Newly Created Custom View As View Of Our Custom Window
    [window setDelegate: self];                             // After Closing Window Close The Application : Set Delegate
    [window makeKeyAndOrderFront: self];                    // Now Actually Show The Window, Give Its Keyboard Focus And Make It Top On The Z-Order
}

-(void)applicationWillTerminate: (NSNotification *)notification                         // Like WM_DESTROY in Windows
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    
    // Log File Closing Code
    if(gpFile_AMC)
    {
        fprintf(gpFile_AMC, "\n");
        fprintf(gpFile_AMC, "=============== ** Program Finished Successfully !!! ** ===============\n");
        fclose(gpFile_AMC);
        gpFile_AMC = NULL;
    }
}

-(void)windowWillClose: (NSNotification *)notification                                  // Like WM_CLOSE in Windows
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    [NSApp terminate: self];
}

-(void)dealloc
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    [super dealloc];
    [glView_AMC release];
    [window release];
}

@end

// Implementaion of Custom View Interface
@implementation GLView
{
    CVDisplayLinkRef displayLink;

    GLuint shaderProgramObject_AMC;

    // ===================== Graph Related VAOs & VBOs =========================
    // For Horizontal lines
    GLuint vao_upper_horizontal_AMC;
    GLuint vbo_upper_horizontal_position_AMC;

    GLuint vao_lower_horizontal_AMC;
    GLuint vbo_lower_horizontal_position_AMC;

    GLuint vbo_color_horizontal_AMC;

    GLuint vao_green_horizontal_AMC;
    GLuint vbo_green_horizontal_position_AMC;
    GLuint vbo_green_horizontal_color_AMC;

    // For Vertical Lines
    GLuint vao_left_vertical_AMC;
    GLuint vbo_left_vertical_position_AMC;

    GLuint vao_right_vertical_AMC;
    GLuint vbo_right_vertical_position_AMC;

    GLuint vbo_color_vertical_AMC;

    GLuint vao_red_vertical_AMC;
    GLuint vbo_red_vertical_position_AMC;
    GLuint vbo_red_vertical_color_AMC;

    // ================= Circle Related VAOs & VBOs ======================
    GLuint vao_circle_AMC;
    GLuint vbo_circle_position_AMC;
    GLuint vbo_circle_color_AMC;

    // ================= Square Related VAOs & VBOs ======================
    GLuint vao_square_AMC;
    GLuint vbo_square_position_AMC;
    GLuint vbo_square_color_AMC;

    // ================= Triangle Related VAOs & VBOs ======================
    GLuint vao_triangle_AMC;
    GLuint vbo_triangle_position_AMC;
    GLuint vbo_triangle_color_AMC;

    GLuint mvpMatrixUniform_AMC;

    mat4 perspectiveProjectionMatrix_AMC; // mat4 is in vmath.h

    // Variable To Handle Switch Between Shapes
    BOOL currentShapeGraph_AMC;
    BOOL currentShapeCircle_AMC;
    BOOL currentShapeSquare_AMC;
    BOOL currentShapeTriangle_AMC;
}

-(id)initWithFrame: (NSRect)frame
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    self = [super initWithFrame: frame];
    if (self)
    {
        currentShapeGraph_AMC = FALSE;
        currentShapeCircle_AMC = FALSE;
        currentShapeSquare_AMC = FALSE;
        currentShapeTriangle_AMC = FALSE;

        // BlueScreen: Step-1 : Declare OpenGL Pixel Format Attribute
        NSOpenGLPixelFormatAttribute attributes[] = {
            NSOpenGLPFAOpenGLProfile,   NSOpenGLProfileVersion4_1Core,
            NSOpenGLPFAScreenMask,      CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
            NSOpenGLPFAColorSize,       24,
            NSOpenGLPFADepthSize,       24,                                                 // Step-1 For Depth
            NSOpenGLPFAAlphaSize,       8,
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADoubleBuffer,
            0
        };
        
        // BlueScreen: Step-2 : Create Pixel Format Using Above Pixel Format Attribute (PFA)
        NSOpenGLPixelFormat *pixelFormat = [[[NSOpenGLPixelFormat alloc]initWithAttributes:attributes]autorelease];
        
        if(pixelFormat == nil)
        {
            fprintf(gpFile_AMC, "Creating Pixel Format Is Failed !!! \n");
            [self uninitialize];
            [self release];
            [NSApp terminate:self];
        }
        
        // BlueScreen: Step-3 : Create OpenGL Context Using Above Pixel Format
        NSOpenGLContext *glContext = [[[NSOpenGLContext alloc]initWithFormat:pixelFormat shareContext:nil]autorelease];
        
        if(glContext == nil)
        {
            fprintf(gpFile_AMC, "Creating OpenGL Context Is Failed !!! \n");
            [self uninitialize];
            [self release];
            [NSApp terminate:self];
        }
        
        // BlueScreen: Step-4 : Set Pixel Format
        [self setPixelFormat:pixelFormat];
        
        // BlueScreen: Step-5 : Set OpenGL Context
        [self setOpenGLContext:glContext];
    }
    return(self);
}

-(void)prepareOpenGL                                                                        // Similar To onSurfaceCreated In Android
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    [super prepareOpenGL];
    [[self openGLContext]makeCurrentContext];                                               // Make Current Context
    
    // Matching Moniter Retracing With The Double Buffer Swapping
    GLint swapInterval = 1;
    [[self openGLContext]setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];      // CP : Context Parameter
    
    int result = [self initialize];
    
    // ----------- Create And Start Display Link --------------
    
    // DisplayLink : Step-1 : Create Display Link According To The Current Active Diplay
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    
    // DisplayLink : Step-2 : Set The Callback Method For OpenGL Thread
    CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);              // 3rd Param Is 6th Param Of MyDisplayLinkCallback
    
    // DisplayLink : Step-3 : Convert NS OpenGL Pixel Format Into CGL Pixel Format
    CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat]CGLPixelFormatObj];
    
    // DisplayLink : Step-4 : Convert NS OpenGL Context Into CGL Context
    CGLContextObj cglContext = (CGLContextObj)[[self openGLContext]CGLContextObj];
    
    // DisplayLink : Step-5 : Set Above Two (CGL Pixel Format & CGL Context) For Display Link
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
    
    // DisplayLink : Step-6 : Start Display Link
    CVDisplayLinkStart(displayLink);
}

-(void)reshape
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    [super reshape];
    [[self openGLContext]makeCurrentContext];
    
    CGLLockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);
    NSRect rect = [self bounds];
    
    int width = rect.size.width;
    int height = rect.size.height;
    
    [self resize: width :height];
    CGLUnlockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);
}

-(void)drawRect: (NSRect)dirtyRect
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    
    // Call Rendering Function Here Too To Avoid Flikerring
    [self drawView];
}

-(void)drawView                                                                             // Our Rendering Function
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    [[self openGLContext]makeCurrentContext];
    
    CGLLockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);
    [self display];
    CGLFlushDrawable((CGLContextObj)[[self openGLContext]CGLContextObj]);
    CGLUnlockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);
}

-(CVReturn)getFrameForTime: (const CVTimeStamp *)outputTime                                 // Function Called Per Frame, Using Auto Release Pool
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    // Call Rendering Function Here TOO
    [self drawView];
    [self myUpdate];
    [pool release];
    
    return(kCVReturnSuccess);
}

-(int)initialize
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    [self printGLInfo];

    // Vertex Shader
	const GLchar* vertexShaderSourceCode_AMC =
		"#version 410 core                          "\
		"\n                                         "\
		"in vec4 aPosition;                         "\
		"in vec4 aColor;                            "\
		"uniform mat4 uMVPMatrix;                   "\
		"out vec4 oColor;                           "\
		"void main(void)                            "\
		"{                                          "\
		"   gl_Position = uMVPMatrix * aPosition;   "\
		"   oColor=aColor;                          "\
		"}                                          ";


	GLuint vertexShaderObject_AMC = glCreateShader(GL_VERTEX_SHADER); // Creates empty shader object

	// below function is made to receive shader source code
	glShaderSource(
		vertexShaderObject_AMC, 
		1, // Number Of Strings passed in 3rd parameter (Can pass multiple strings we passed only one)
		(const GLchar**)&vertexShaderSourceCode_AMC,
		NULL // If multiple strings are there in 3rd param then it will be array of lengths of those multiple strings(We have only one so consider whole string)
	);

	// To compile shader source code(To convert human understandable to m/c i.e. GPU)
	glCompileShader(vertexShaderObject_AMC);

	GLint status_AMC = 0;
	GLint infoLogLength_AMC = 0;
	GLchar* szInfoLog_AMC = NULL;

	// To get Error in our own variable
	glGetShaderiv(vertexShaderObject_AMC, GL_COMPILE_STATUS, &status_AMC);

	if (status_AMC == GL_FALSE)
	{
		glGetShaderiv(vertexShaderObject_AMC, GL_INFO_LOG_LENGTH, &infoLogLength_AMC);
		if (infoLogLength_AMC > 0)
		{
			szInfoLog_AMC = (GLchar*)malloc(infoLogLength_AMC + 1);
			if (szInfoLog_AMC != NULL)
			{
				glGetShaderInfoLog(vertexShaderObject_AMC, infoLogLength_AMC + 1, NULL, szInfoLog_AMC);
				fprintf(gpFile_AMC, "Vertex Shader Compilation Error LOG : %s\n", szInfoLog_AMC);
				free(szInfoLog_AMC);
				szInfoLog_AMC = NULL;
			}
		}
		[self uninitialize];
        [self release];
        [NSApp terminate:self];
	}

	// Fragment Shader
	const GLchar* fragmentShaderSourceCode_AMC =
		"#version 410 core                          "\
	    "\n                                         "\
		"in vec4 oColor;                            "\
		"out vec4 FragColor;                        "\
		"void main(void)                            "\
		"{                                          "\
		"   FragColor=oColor;                       "\
		"}                                          ";


	GLuint fragmentShaderObject_AMC = glCreateShader(GL_FRAGMENT_SHADER);

	glShaderSource(fragmentShaderObject_AMC, 1, (const GLchar**)&fragmentShaderSourceCode_AMC, NULL);

	glCompileShader(fragmentShaderObject_AMC);

	status_AMC = 0;
	infoLogLength_AMC = 0;
	szInfoLog_AMC = NULL;

	glGetShaderiv(fragmentShaderObject_AMC, GL_COMPILE_STATUS, &status_AMC);

	if (status_AMC == GL_FALSE)
	{
		glGetShaderiv(fragmentShaderObject_AMC, GL_INFO_LOG_LENGTH, &infoLogLength_AMC); // GL_SHADER_INFO_LOG_LENGTH
		if (infoLogLength_AMC > 0)
		{
			szInfoLog_AMC = (GLchar*)malloc(infoLogLength_AMC);
			if (szInfoLog_AMC != NULL)
			{
				glGetShaderInfoLog(fragmentShaderObject_AMC, infoLogLength_AMC, NULL, szInfoLog_AMC);
				fprintf(gpFile_AMC, "Fragment Shader Compilation Error LOG : %s\n", szInfoLog_AMC);
				free(szInfoLog_AMC);
				szInfoLog_AMC = NULL;
			}
		}
		[self uninitialize];                                            // Change In mm
        [self release];                                                 // Change In mm
        [NSApp terminate:self];                                         // Change In mm
	}

	// Shader Program
	shaderProgramObject_AMC = glCreateProgram();
	glAttachShader(shaderProgramObject_AMC, vertexShaderObject_AMC);
	glAttachShader(shaderProgramObject_AMC, fragmentShaderObject_AMC);

	glBindAttribLocation(shaderProgramObject_AMC, AMC_ATTRIBUTE_POSITION, "aPosition");
	glBindAttribLocation(shaderProgramObject_AMC, AMC_ATTRIBUTE_COLOR, "aColor");


	glLinkProgram(shaderProgramObject_AMC);

	status_AMC = 0;
	infoLogLength_AMC = 0;
	szInfoLog_AMC = NULL;

	glGetProgramiv(shaderProgramObject_AMC, GL_LINK_STATUS, &status_AMC);

	if (status_AMC == GL_FALSE)
	{
		glGetProgramiv(shaderProgramObject_AMC, GL_INFO_LOG_LENGTH, &infoLogLength_AMC);
		if (infoLogLength_AMC > 0)
		{
			szInfoLog_AMC = (GLchar*)malloc(infoLogLength_AMC);
			if (szInfoLog_AMC != NULL)
			{
				glGetProgramInfoLog(shaderProgramObject_AMC, infoLogLength_AMC, NULL, szInfoLog_AMC);
				fprintf(gpFile_AMC, "Shader Program Linking Error LOG : %s\n", szInfoLog_AMC);
				free(szInfoLog_AMC);
				szInfoLog_AMC = NULL;
			}
		}
		[self uninitialize];                                            // Change In mm
        [self release];                                                 // Change In mm
        [NSApp terminate:self];                                         // Change In mm
	}

	// Get Shader Uniform Locations
	mvpMatrixUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uMVPMatrix");

    [self initialize_graph];
    [self initialize_circle];
    [self initialize_square];
    [self initialize_triangle];
    
    // Step - 2 : For Depth Enable
    glClearDepth(1.0f);         // Compulsory
    glEnable(GL_DEPTH_TEST);    // Compulsory
    glDepthFunc(GL_LEQUAL);     // Compulsory

    // Set The Clear Color Of Window To Black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

	// initialize ortho mat
	perspectiveProjectionMatrix_AMC = vmath::mat4::identity();

    [self resize:WIN_WIDTH :WIN_HEIGHT];                            // resize(WIN_WIDTH, WIN_HEIGHT); change mm
    
    return(0);
}

-(void)initialize_graph
{
	// ========================= Initialization For Horizontal Lines ==============================

	// *********** Upper Horizontal Lines *******************

	GLfloat upper_horizontal_lines_position_AMC[80 * 2];
	for (int i = 0; i < 40; i++)
	{
		GLfloat y = i * 0.031f;
		upper_horizontal_lines_position_AMC[i * 4] = -1.7f;
		upper_horizontal_lines_position_AMC[i * 4 + 1] = y;
		upper_horizontal_lines_position_AMC[i * 4 + 2] = 1.7f;
		upper_horizontal_lines_position_AMC[i * 4 + 3] = y;
	}

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_upper_horizontal_AMC);
	glBindVertexArray(vao_upper_horizontal_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_upper_horizontal_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_upper_horizontal_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(upper_horizontal_lines_position_AMC), upper_horizontal_lines_position_AMC, GL_STATIC_DRAW);

	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		2,
		GL_FLOAT,
		GL_FALSE,
		2 * sizeof(GLfloat),
		NULL
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Color
	glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 0.0f, 1.0f);
	glBindVertexArray(0);

	// *********** Lower Horizontal Lines *******************

	GLfloat lower_horizontal_lines_position_AMC[80 * 2];
	for (int i = 0; i < 40; i++)
	{
		GLfloat y = i * -0.031f;
		lower_horizontal_lines_position_AMC[i * 4] = -1.7f;
		lower_horizontal_lines_position_AMC[i * 4 + 1] = y;
		lower_horizontal_lines_position_AMC[i * 4 + 2] = 1.7f;
		lower_horizontal_lines_position_AMC[i * 4 + 3] = y;
	}

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_lower_horizontal_AMC);
	glBindVertexArray(vao_lower_horizontal_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_lower_horizontal_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_lower_horizontal_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(lower_horizontal_lines_position_AMC), lower_horizontal_lines_position_AMC, GL_STATIC_DRAW);

	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		2,
		GL_FLOAT,
		GL_FALSE,
		2 * sizeof(GLfloat),
		NULL
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Color
	glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 0.0f, 1.0f);

	glBindVertexArray(0);

	// *********** Green Horizontal Line *******************

	GLfloat green_horizontal_line_position_AMC[] = {
		-1.7f, 0.0f, 1.7f, 0.0f
	};

	GLfloat green_horizontal_line_color_AMC[] = {
		 0.0f, 1.0f, 0.0f,
		 0.0f, 1.0f, 0.0f
	};

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_green_horizontal_AMC);
	glBindVertexArray(vao_green_horizontal_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_green_horizontal_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_green_horizontal_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(green_horizontal_line_position_AMC), green_horizontal_line_position_AMC, GL_STATIC_DRAW);

	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		2,
		GL_FLOAT,
		GL_FALSE,
		2 * sizeof(GLfloat),
		NULL
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Color
	glGenBuffers(1, &vbo_green_horizontal_color_AMC);

	glBindBuffer(GL_ARRAY_BUFFER, vbo_green_horizontal_color_AMC);

	glBufferData(GL_ARRAY_BUFFER, sizeof(green_horizontal_line_color_AMC), green_horizontal_line_color_AMC, GL_STATIC_DRAW);

	glVertexAttribPointer(
		AMC_ATTRIBUTE_COLOR,
		3,
		GL_FLOAT,
		GL_FALSE,
		3 * sizeof(GLfloat),
		NULL
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_COLOR);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glBindVertexArray(0);

	// ========================= Initialization For Vertical Lines ==============================

	// ******************* Left Vertical Lines *******************

	GLfloat left_vertical_lines_position_AMC[80 * 2];
	for (int i = 0; i < 40; i++)
	{
		GLfloat x = i * -0.0436f;
		left_vertical_lines_position_AMC[i * 4] = x;
		left_vertical_lines_position_AMC[i * 4 + 1] = -1.21f;
		left_vertical_lines_position_AMC[i * 4 + 2] = x;
		left_vertical_lines_position_AMC[i * 4 + 3] = 1.21f;
	}

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_left_vertical_AMC);
	glBindVertexArray(vao_left_vertical_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_left_vertical_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_left_vertical_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(left_vertical_lines_position_AMC), left_vertical_lines_position_AMC, GL_STATIC_DRAW);

	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		2,
		GL_FLOAT,
		GL_FALSE,
		2 * sizeof(GLfloat),
		NULL
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Color
	glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 0.0f, 1.0f);
	glBindVertexArray(0);

	// ******************* Right Vertical Lines *******************

	GLfloat right_vertical_lines_position_AMC[80 * 2];
	for (int i = 0; i < 40; i++)
	{
		GLfloat x = i * 0.0436f;
		right_vertical_lines_position_AMC[i * 4] = x;
		right_vertical_lines_position_AMC[i * 4 + 1] = -1.21f;
		right_vertical_lines_position_AMC[i * 4 + 2] = x;
		right_vertical_lines_position_AMC[i * 4 + 3] = 1.21f;
	}

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_right_vertical_AMC);
	glBindVertexArray(vao_right_vertical_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_right_vertical_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_right_vertical_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(right_vertical_lines_position_AMC), right_vertical_lines_position_AMC, GL_STATIC_DRAW);

	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		2,
		GL_FLOAT,
		GL_FALSE,
		2 * sizeof(GLfloat),
		NULL
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Color
	glVertexAttrib3f(AMC_ATTRIBUTE_COLOR, 0.0f, 0.0f, 1.0f);
	glBindVertexArray(0);

	// *********** Red Vertical Line *******************

	GLfloat red_vertical_line_position_AMC[] = {
		 0.0f, 1.21f, 0.0f, -1.21f
	};

	GLfloat red_vertical_line_color_AMC[] = {
		 1.0f, 0.0f, 0.0f,
		 1.0f, 0.0f, 0.0f
	};

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_red_vertical_AMC);
	glBindVertexArray(vao_red_vertical_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_red_vertical_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_red_vertical_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(red_vertical_line_position_AMC), red_vertical_line_position_AMC, GL_STATIC_DRAW);

	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		2,
		GL_FLOAT,
		GL_FALSE,
		2 * sizeof(GLfloat),
		NULL
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Color
	glGenBuffers(1, &vbo_red_vertical_color_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_red_vertical_color_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(red_vertical_line_color_AMC), red_vertical_line_color_AMC, GL_STATIC_DRAW);

	glVertexAttribPointer(
		AMC_ATTRIBUTE_COLOR,
		3,
		GL_FLOAT,
		GL_FALSE,
		3 * sizeof(GLfloat),
		NULL
	);

	glEnableVertexAttribArray(AMC_ATTRIBUTE_COLOR);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glBindVertexArray(0);
}

-(void)initialize_circle
{
	int segments_AMC = 50;
	float radius_AMC = 1.0f;
	GLfloat vertices_AMC[102];
	GLfloat angleStep_AMC = 2.0f * M_PI / segments_AMC;

	for (int i = 0; i <= segments_AMC; i++) 
	{
		float angle_AMC = i * angleStep_AMC;
		vertices_AMC[2 * i] = cos(angle_AMC) * radius_AMC;
		vertices_AMC[2 * i + 1] = sin(angle_AMC) * radius_AMC;
	}

	GLfloat colors_AMC[153];
	float color_AMC[] = { 1.0f, 1.0f, 0.0f };

	for (int i = 0; i <= segments_AMC; i++) 
	{
		colors_AMC[3 * i] = color_AMC[0];
		colors_AMC[3 * i + 1] = color_AMC[1];
		colors_AMC[3 * i + 2] = color_AMC[2];
	}

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_circle_AMC);
	glBindVertexArray(vao_circle_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_circle_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_circle_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, 102 * sizeof(float), vertices_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		2,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Color
	glGenBuffers(1, &vbo_circle_color_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_circle_color_AMC);
	glBufferData(GL_ARRAY_BUFFER, 153 * sizeof(float), colors_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_COLOR,
		3,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_COLOR);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glBindVertexArray(0);
}

-(void)initialize_square
{
	const GLfloat square_position_AMC[] =
	{
		 1.0f,  1.0f,  0.0f,
		-1.0f,  1.0f,  0.0f,
		-1.0f, -1.0f,  0.0f,
		 1.0f, -1.0f,  0.0f
	};

	const GLfloat square_color_AMC[] =
	{
		1.0f, 1.0f, 0.0f,
		1.0f, 1.0f, 0.0f,
		1.0f, 1.0f, 0.0f,
		1.0f, 1.0f, 0.0f
	};

	// ======================== SQUARE VAO =====================================

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_square_AMC);
	glBindVertexArray(vao_square_AMC);

	// VBO (Vertex Buffer Object) For Square Position
	glGenBuffers(1, &vbo_square_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_square_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(square_position_AMC), square_position_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		3,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Square Color
	glGenBuffers(1, &vbo_square_color_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_square_color_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(square_color_AMC), square_color_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_COLOR,
		3,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_COLOR);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glBindVertexArray(0);
}

-(void)initialize_triangle
{
	const GLfloat triangle_position_AMC[] =
	{
		 0.00f,  1.0f, 0.0f,
		-0.86f, -0.5f, 0.0f,
		 0.86f, -0.5f, 0.0f
	};

	const GLfloat triangle_color_AMC[] =
	{
		1.0f, 1.0f, 0.0f,
		1.0f, 1.0f, 0.0f,
		1.0f, 1.0f, 0.0f
	};

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_triangle_AMC);
	glBindVertexArray(vao_triangle_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_triangle_position_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_triangle_position_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(triangle_position_AMC), triangle_position_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_POSITION,
		3,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Color
	glGenBuffers(1, &vbo_triangle_color_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_triangle_color_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(triangle_color_AMC), triangle_color_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_COLOR,
		3,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_COLOR);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glBindVertexArray(0);
}

-(void)printGLInfo
{
    // Variable Declarations
	GLint i_AMC;
	GLint numExtensions_AMC;

    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    fprintf(gpFile_AMC, ":::::::::::::::::::::::::::::::::::::::::::::::\n");
    fprintf(gpFile_AMC, "           OpenGL INFORMATION\n");
    fprintf(gpFile_AMC, ":::::::::::::::::::::::::::::::::::::::::::::::\n");
    fprintf(gpFile_AMC, "OpenGL Vendor      : %s\n",        glGetString(GL_VENDOR));
    fprintf(gpFile_AMC, "OpenGL Renderer    : %s\n",        glGetString(GL_RENDERER));
    fprintf(gpFile_AMC, "OpenGL Version     : %s\n",        glGetString(GL_VERSION));
    fprintf(gpFile_AMC, "GLSL Version       : %s\n",        glGetString(GL_SHADING_LANGUAGE_VERSION));

	glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions_AMC);
	for (i_AMC = 0; i_AMC < numExtensions_AMC; i_AMC++)
	{
		fprintf(gpFile_AMC, "%s\n", glGetStringi(GL_EXTENSIONS, i_AMC));
	}
 
    fprintf(gpFile_AMC, ":::::::::::::::::::::::::::::::::::::::::::::::\n");

    GLfloat range[2];
    glGetFloatv(GL_LINE_WIDTH_RANGE, range);
    fprintf(gpFile_AMC, "Supported Line Width Range : %f - %f\n", range[0], range[1]);
}

-(void)resize:(int)width_AMC :(int)height_AMC
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    if(height_AMC <= 0)
    {
        height_AMC = 1;
    }
    
    glViewport(0, 0, (GLsizei)width_AMC, (GLsizei)height_AMC);

	// Set perspective projection matrix
	perspectiveProjectionMatrix_AMC = vmath::perspective(   // glFrustum()
		45.0f,                                              // Field Of View (fovy) Radian considered
		(GLfloat)width_AMC / (GLfloat)height_AMC,           // Aspect Ratio
		0.1f,                                               // Near standered Value
		100.0f                                              // Far Standered Value
	);
}

-(void)display
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                                     // Step-3 Depth

	glUseProgram(shaderProgramObject_AMC);

	// Transformation
	mat4 modelViewMtrix_AMC = vmath::translate(0.0f, 0.0f, -3.0f);
	mat4 modelViewProjectionMatrix_AMC = perspectiveProjectionMatrix_AMC * modelViewMtrix_AMC; // here order of mult is VVIMP.

	// Push above MVP into vertex shhadr's MVP uniform
	glUniformMatrix4fv(mvpMatrixUniform_AMC, 1, GL_FALSE, modelViewProjectionMatrix_AMC);

	[self handle_shape_switch];

	glUseProgram(0);
}

-(void)handle_shape_switch
{
	if (currentShapeGraph_AMC == TRUE)
	{
		[self draw_graph];
	}

	if (currentShapeCircle_AMC == TRUE)
	{
		[self draw_circle];
	}

	if (currentShapeSquare_AMC == TRUE)
	{
		[self draw_square];
	}

	if (currentShapeTriangle_AMC == TRUE)
	{
		[self draw_triangle];
	}
}

-(void)draw_graph
{
	// Variable Declarations 
	float normalLineWidth_AMC = 0.125000;
	float largerLineWidth_AMC = 1.000000;

	// ============================== Draw Horizontal Lines =================================

	// Draw upper horiontal lines using below loop
	glBindVertexArray(vao_upper_horizontal_AMC);

	for (int i = 0; i < 40; i++)
	{
		// Check if this is a 5th line
		if (i % 5 == 4) 
		{
			glLineWidth(largerLineWidth_AMC);
		}
		else 
		{
			glLineWidth(normalLineWidth_AMC);
		}

		// Draw the current line
		glDrawArrays(GL_LINES, i * 2, 2);
	}

	glBindVertexArray(0);

	// Draw Lower horiontal lines using below loop
	glBindVertexArray(vao_lower_horizontal_AMC);

	for (int i = 0; i < 40; i++)
	{
		// Check if this is a 5th line
		if (i % 5 == 4) 
		{
			glLineWidth(largerLineWidth_AMC);
		}
		else 
		{
			glLineWidth(normalLineWidth_AMC);
		}

		// Draw the current line
		glDrawArrays(GL_LINES, i * 2, 2);
	}

	glBindVertexArray(0);

	// Draw green horiontal line
	glBindVertexArray(vao_green_horizontal_AMC);
	glLineWidth(largerLineWidth_AMC);
	glDrawArrays(GL_LINES, 0, 2);
	glBindVertexArray(0);

	// ============================== Draw Vertical Lines =================================

	// Draw left Vertical lines using below loop
	glBindVertexArray(vao_left_vertical_AMC);

	for (int i = 0; i < 40; i++)
	{
		// Check if this is a 5th line
		if (i % 5 == 4) 
		{
			glLineWidth(largerLineWidth_AMC);
		}
		else 
		{
			glLineWidth(normalLineWidth_AMC);
		}

		// Draw the current line
		glDrawArrays(GL_LINES, i * 2, 2);
	}

	glBindVertexArray(0);

	// Draw right Vertical lines using below loop
	glBindVertexArray(vao_right_vertical_AMC);

	for (int i = 0; i < 40; i++)
	{
		// Check if this is a 5th line
		if (i % 5 == 4) 
		{
			glLineWidth(largerLineWidth_AMC);
		}
		else 
		{
			glLineWidth(normalLineWidth_AMC);
		}

		// Draw the current line
		glDrawArrays(GL_LINES, i * 2, 2);
	}

	glBindVertexArray(0);

	// Draw Red Vertical line
	glBindVertexArray(vao_red_vertical_AMC);
	glLineWidth(largerLineWidth_AMC);
	glDrawArrays(GL_LINES, 0, 2);
	glBindVertexArray(0);
}

-(void)draw_circle
{
	glBindVertexArray(vao_circle_AMC);
	glDrawArrays(GL_LINE_LOOP, 0, 51);
	glBindVertexArray(0);
}

-(void)draw_square
{
	glBindVertexArray(vao_square_AMC);
	glDrawArrays(GL_LINE_LOOP, 0, 4);
	glBindVertexArray(0);
}

-(void)draw_triangle
{
	glBindVertexArray(vao_triangle_AMC);
	glDrawArrays(GL_LINE_LOOP, 0, 3);
	glBindVertexArray(0);
}

-(void)myUpdate
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
}

-(void)uninitialize
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

    if (shaderProgramObject_AMC)
	{
		glUseProgram(shaderProgramObject_AMC);

		GLint numShaders_AMC = 0;
		glGetProgramiv(shaderProgramObject_AMC, GL_ATTACHED_SHADERS, &numShaders_AMC);

		if (numShaders_AMC > 0)
		{
			GLuint* pShaders_AMC = (GLuint*)malloc(numShaders_AMC * sizeof(GLuint));
			if (pShaders_AMC != NULL)
			{
				glGetAttachedShaders(shaderProgramObject_AMC, numShaders_AMC, NULL, pShaders_AMC);
				for (GLint i = 0; i < numShaders_AMC; i++)
				{
					glDetachShader(shaderProgramObject_AMC, pShaders_AMC[i]);
					glDeleteShader(pShaders_AMC[i]);
					pShaders_AMC[i] = 0;
				}
				free(pShaders_AMC);
				pShaders_AMC = NULL;
			}
		}

		glUseProgram(0);
		glDeleteProgram(shaderProgramObject_AMC);
		shaderProgramObject_AMC = 0;
	}

    [self uninitialize_graph];
    [self uninitialize_circle];
    [self uninitialize_square];
    [self uninitialize_triangle];
}

-(void)uninitialize_graph
{
	// ========================= Uninitialization For Horizontal Lines ==============================
	
	// Delete VBO (Vertex Buffer Object) for green color
	if (vbo_green_horizontal_color_AMC)
	{
		glDeleteBuffers(1, &vbo_green_horizontal_color_AMC);
		vbo_green_horizontal_color_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for horizontal lines color
	if (vbo_color_horizontal_AMC)
	{
		glDeleteBuffers(1, &vbo_color_horizontal_AMC);
		vbo_color_horizontal_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for green line position
	if (vbo_green_horizontal_position_AMC)
	{
		glDeleteBuffers(1, &vbo_green_horizontal_position_AMC);
		vbo_green_horizontal_position_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for upper lines position
	if (vbo_upper_horizontal_position_AMC)
	{
		glDeleteBuffers(1, &vbo_upper_horizontal_position_AMC);
		vbo_upper_horizontal_position_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for lower lines position
	if (vbo_lower_horizontal_position_AMC)
	{
		glDeleteBuffers(1, &vbo_lower_horizontal_position_AMC);
		vbo_lower_horizontal_position_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for green line position
	if (vao_green_horizontal_AMC)
	{
		glDeleteVertexArrays(1, &vao_green_horizontal_AMC);
		vao_green_horizontal_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for upper lines position
	if (vao_upper_horizontal_AMC)
	{
		glDeleteVertexArrays(1, &vao_upper_horizontal_AMC);
		vao_upper_horizontal_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for lower lines position
	if (vao_lower_horizontal_AMC)
	{
		glDeleteVertexArrays(1, &vao_lower_horizontal_AMC);
		vao_lower_horizontal_AMC = 0;
	}

	// ========================= Uninitialization For Vertical Lines ==============================

	// Delete VBO (Vertex Buffer Object) for red color
	if (vbo_red_vertical_color_AMC)
	{
		glDeleteBuffers(1, &vbo_red_vertical_color_AMC);
		vbo_red_vertical_color_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for vertiocal lines color
	if (vbo_color_vertical_AMC)
	{
		glDeleteBuffers(1, &vbo_color_vertical_AMC);
		vbo_color_vertical_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for red line position
	if (vbo_red_vertical_position_AMC)
	{
		glDeleteBuffers(1, &vbo_red_vertical_position_AMC);
		vbo_red_vertical_position_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for left lines position
	if (vbo_left_vertical_position_AMC)
	{
		glDeleteBuffers(1, &vbo_left_vertical_position_AMC);
		vbo_left_vertical_position_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for right lines position
	if (vbo_right_vertical_position_AMC)
	{
		glDeleteBuffers(1, &vbo_right_vertical_position_AMC);
		vbo_right_vertical_position_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for red line position
	if (vbo_red_vertical_position_AMC)
	{
		glDeleteVertexArrays(1, &vbo_red_vertical_position_AMC);
		vbo_red_vertical_position_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for left lines position
	if (vao_left_vertical_AMC)
	{
		glDeleteVertexArrays(1, &vao_left_vertical_AMC);
		vao_left_vertical_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for right lines position
	if (vao_right_vertical_AMC)
	{
		glDeleteVertexArrays(1, &vao_right_vertical_AMC);
		vao_right_vertical_AMC = 0;
	}
}

-(void)uninitialize_circle
{
	// Delete VBO (Vertex Buffer Object) for circle color
	if (vbo_circle_color_AMC)
	{
		glDeleteBuffers(1, &vbo_circle_color_AMC);
		vbo_circle_color_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for circle position
	if (vbo_circle_position_AMC)
	{
		glDeleteBuffers(1, &vbo_circle_position_AMC);
		vbo_circle_position_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for circle
	if (vao_circle_AMC)
	{
		glDeleteVertexArrays(1, &vao_circle_AMC);
		vao_circle_AMC = 0;
	}
}

-(void)uninitialize_square
{
	// Delete VBO (Vertex Buffer Object) for square color
	if (vbo_square_color_AMC)
	{
		glDeleteBuffers(1, &vbo_square_color_AMC);
		vbo_square_color_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for square position
	if (vbo_square_position_AMC)
	{
		glDeleteBuffers(1, &vbo_square_position_AMC);
		vbo_square_position_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for square
	if (vao_square_AMC)
	{
		glDeleteVertexArrays(1, &vao_square_AMC);
		vao_square_AMC = 0;
	}
}

-(void)uninitialize_triangle
{
	// Delete VBO (Vertex Buffer Object) for triangle color
	if (vbo_triangle_color_AMC)
	{
		glDeleteBuffers(1, &vbo_triangle_color_AMC);
		vbo_triangle_color_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for triangle position
	if (vbo_triangle_position_AMC)
	{
		glDeleteBuffers(1, &vbo_triangle_position_AMC);
		vbo_triangle_position_AMC = 0;
	}

	// Delete VAO (Vertex Array Object) for triangle
	if (vao_triangle_AMC)
	{
		glDeleteVertexArrays(1, &vao_triangle_AMC);
		vao_triangle_AMC = 0;
	}
}

-(BOOL)acceptsFirstResponder
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    [[self window]makeFirstResponder: self];
    return(YES);
}

-(void)keyDown: (NSEvent *)event
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    int key = (int)[[event characters]characterAtIndex: 0];
    
    switch(key)
    {
        case 27:
            [self uninitialize];
            [self release];
            [NSApp terminate: self];
            break;
            
        case 'F':
        case 'f':
            [[self window]toggleFullScreen: self];
            break;

		case 'G':
		case 'g':
			if (currentShapeGraph_AMC == FALSE)
			{
				currentShapeGraph_AMC = TRUE;
			}
			else
			{
				currentShapeGraph_AMC = FALSE;
			}
			break;
		case 'T':
		case 't':
			if (currentShapeTriangle_AMC == FALSE)
			{
				currentShapeTriangle_AMC = TRUE;
			}
			else
			{
				currentShapeTriangle_AMC = FALSE;
			}
			break;
		case 'C':
		case 'c':
			if (currentShapeCircle_AMC == FALSE)
			{
				currentShapeCircle_AMC = TRUE;
			}
			else
			{
				currentShapeCircle_AMC = FALSE;
			}
			break;
		case 'S':
		case 's':
			if (currentShapeSquare_AMC == FALSE)
			{
				currentShapeSquare_AMC = TRUE;
			}
			else
			{
				currentShapeSquare_AMC = FALSE;
			}
			break;
            
        default:
            break;
    }
}

-(void)mouseDown: (NSEvent *)event
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
}

-(void)rightMouseDown: (NSEvent *)event
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
}

-(void)dealloc
{
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

// Definition Of Global Callback Function
CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
                               const CVTimeStamp *now,
                               const CVTimeStamp *outputTime,
                               CVOptionFlags flagsIn,
                               CVOptionFlags *flagsOut,
                               void *displayLinkContext)
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    CVReturn result = [(GLView*)displayLinkContext getFrameForTime:outputTime];
    return(result);
}
