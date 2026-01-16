#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <QuartzCore/CVDisplayLink.h>	// Core Video Display Link
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "Sphere.h"

#import "vmath.h"
using   namespace vmath;

#define WIN_WIDTH   800.0
#define WIN_HEIGHT  600.0

// FBO Releated Macros
#define FBO_WIDTH 	512.0
#define FBO_HEIGHT 	512.0

// Global Function Declarations
CVReturn MyDisplayLinkCallback(CVDisplayLinkRef, const CVTimeStamp *, const CVTimeStamp *, CVOptionFlags, CVOptionFlags *, void *);

// Global Variable Declarations
FILE* gpFile_AMC = NULL;

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_NORMAL,
    AMC_ATTRIBUTE_TEXCOORD
};

struct Light
{
	vec3 ambient_sphere_AMC;
	vec3 diffuse_sphere_AMC;
	vec3 speculer_sphere_AMC;
	vec4 position_sphere_AMC;
};
struct Light light_sphere_AMC[3];

GLfloat materialAmbient_sphere_AMC[] = { 0.0f, 0.0f, 0.0f, 1.0f };
GLfloat materialDiffuse_sphere_AMC[] = { 0.5f, 0.2f, 0.7f, 1.0f };
GLfloat materialSpecular_sphere_AMC[] = { 0.7f, 0.7f, 0.7f, 1.0f };
GLfloat materialShininess_sphere_AMC = 128.0f;

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

	// ================= Cube Releated Variable ========================
    GLuint shaderProgramObject_cube_AMC;
    
    GLuint vao_cube_AMC;
    GLuint vbo_position_cube_AMC;
	GLuint vbo_texcoord_cube_AMC;

    GLuint mvpMatrixUniform_cube_AMC;
	GLuint textureSamplerUniform_cube_AMC;

    mat4 perspectiveProjectionMatrix_cube_AMC;       // mat4 is in vmath.h

    // Variable For Shape Rotation
    GLfloat angle_cube_AMC;

	// ================= Sphere Related Variables =======================

    GLuint shaderProgramObject_sphere_AMC;
    mat4 perspectiveProjectionMatrix_sphere_AMC;       // mat4 is in vmath.h

    GLuint gNumVertices_AMC;
    GLuint gNumElements_AMC;

    float sphere_vertices_AMC[1146];
    float sphere_normals_AMC[1146];
    float sphere_texcoords_AMC[764];
    unsigned short sphere_elements_AMC[2280];

    GLuint vao_sphere_AMC;
    GLuint vbo_position_sphere_AMC;
    GLuint vbo_normals_sphere_AMC;
    GLuint vbo_texcoord_sphere_AMC;
    GLuint vbo_element_sphere_AMC;

	GLuint modelMatrixUniform_sphere_AMC;
	GLuint viewMatrixUniform_sphere_AMC;
	GLuint projectionMatrixUniform_sphere_AMC;

	// Variables For Light
	GLuint lightAmbientUniform_sphere_AMC[3];
	GLuint lightDiffuseUniform_sphere_AMC[3];
	GLuint lightSpecularUniform_sphere_AMC[3];
	GLuint lightPositionUniform_sphere_AMC[3];

	GLuint materialAmbientUniform_sphere_AMC;
	GLuint materialDiffuseUniform_sphere_AMC;
	GLuint materialSpecularUniform_sphere_AMC;
	GLuint materialShininessUniform_sphere_AMC;

	GLuint keyPressedUniform_sphere_AMC;

	BOOL bLightningEnabled_sphere_AMC;
	BOOL isPerFragmentChoosed_sphere_AMC;

	GLfloat lightAngleZero_sphere_AMC;
	GLfloat lightAngleOne_sphere_AMC;
	GLfloat lightAngleTwo_sphere_AMC;

	// FBO Related Variables
	GLint winWidth_AMC;
	GLint winHeight_AMC;

	GLuint fbo_AMC;
	GLuint rbo_AMC;
	GLuint textureFBO_AMC;
	BOOL bFboResult_AMC;
}

-(id)initWithFrame: (NSRect)frame
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    self = [super initWithFrame: frame];
    if (self)
    {
		// Initialize Variables
		winWidth_AMC = 0;
		winHeight_AMC = 0;

		fbo_AMC = 0;
		rbo_AMC = 0;
		textureFBO_AMC = 0;
		bFboResult_AMC = FALSE;

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
            [self uninitialize_cube];
            [self release];
            [NSApp terminate:self];
        }
        
        // BlueScreen: Step-3 : Create OpenGL Context Using Above Pixel Format
        NSOpenGLContext *glContext = [[[NSOpenGLContext alloc]initWithFormat:pixelFormat shareContext:nil]autorelease];
        
        if(glContext == nil)
        {
            fprintf(gpFile_AMC, "Creating OpenGL Context Is Failed !!! \n");
            [self uninitialize_cube];
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
    
    int result = [self initialize_cube];
    
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
    
    [self resize_cube:width :height];
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
    [self display_cube];
    CGLFlushDrawable((CGLContextObj)[[self openGLContext]CGLContextObj]);
    CGLUnlockContext((CGLContextObj)[[self openGLContext]CGLContextObj]);
}

-(CVReturn)getFrameForTime: (const CVTimeStamp *)outputTime                                 // Function Called Per Frame, Using Auto Release Pool
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
    
    // Call Rendering Function Here TOO
    [self drawView];
    [self update_cube];
    [pool release];
    
    return(kCVReturnSuccess);
}

-(int)initialize_cube
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    [self printGLInfo];

    // Vertex Shader
	const GLchar* vertexShaderSourceCode_AMC =
		"#version 410 core                          "\
		"\n                                         "\
		"in vec4 aPosition;                         "\
		"in vec2 aTexCoord;                         "\
		"uniform mat4 uMVPMatrix;                   "\
		"out vec2 oTexCoord;                        "\
		"void main(void)                            "\
		"{                                          "\
		"   gl_Position = uMVPMatrix * aPosition;   "\
		"   oTexCoord=aTexCoord;                    "\
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
		[self uninitialize_cube];
        [self release];
        [NSApp terminate:self];
	}

	// Fragment Shader
	const GLchar* fragmentShaderSourceCode_AMC =
		"#version 410 core                                  "\
		"\n                                                 "\
		"in vec2 oTexCoord;                                 "\
		"uniform sampler2D uTextureSampler;                 "\
		"out vec4 FragColor;                                "\
		"void main(void)                                    "\
		"{                                                  "\
		"   FragColor=texture(uTextureSampler, oTexCoord);  "\
		"}                                                  ";

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
		[self uninitialize_cube];                                            // Change In mm
        [self release];                                                 // Change In mm
        [NSApp terminate:self];                                         // Change In mm
	}

	// Shader Program
	shaderProgramObject_cube_AMC = glCreateProgram();
	glAttachShader(shaderProgramObject_cube_AMC, vertexShaderObject_AMC);
	glAttachShader(shaderProgramObject_cube_AMC, fragmentShaderObject_AMC);

	glBindAttribLocation(shaderProgramObject_cube_AMC, AMC_ATTRIBUTE_POSITION, "aPosition");
	glBindAttribLocation(shaderProgramObject_cube_AMC, AMC_ATTRIBUTE_TEXCOORD, "aTexCoord");

	glLinkProgram(shaderProgramObject_cube_AMC);

	status_AMC = 0;
	infoLogLength_AMC = 0;
	szInfoLog_AMC = NULL;

	glGetProgramiv(shaderProgramObject_cube_AMC, GL_LINK_STATUS, &status_AMC);

	if (status_AMC == GL_FALSE)
	{
		glGetProgramiv(shaderProgramObject_cube_AMC, GL_INFO_LOG_LENGTH, &infoLogLength_AMC);
		if (infoLogLength_AMC > 0)
		{
			szInfoLog_AMC = (GLchar*)malloc(infoLogLength_AMC);
			if (szInfoLog_AMC != NULL)
			{
				glGetProgramInfoLog(shaderProgramObject_cube_AMC, infoLogLength_AMC, NULL, szInfoLog_AMC);
				fprintf(gpFile_AMC, "Shader Program Linking Error LOG : %s\n", szInfoLog_AMC);
				free(szInfoLog_AMC);
				szInfoLog_AMC = NULL;
			}
		}
		[self uninitialize_cube];                                            // Change In mm
        [self release];                                                 // Change In mm
        [NSApp terminate:self];                                         // Change In mm
	}

	// Get Shader Uniform Locations
	mvpMatrixUniform_cube_AMC = glGetUniformLocation(shaderProgramObject_cube_AMC, "uMVPMatrix");
	textureSamplerUniform_cube_AMC = glGetUniformLocation(shaderProgramObject_cube_AMC, "uTextureSampler");

	const GLfloat cube_position_AMC[] =
	{
		 // front
		 1.0f,  1.0f,  1.0f, // top-right of front
		-1.0f,  1.0f,  1.0f, // top-left of front
		-1.0f, -1.0f,  1.0f, // bottom-left of front
		 1.0f, -1.0f,  1.0f, // bottom-right of front

		 // right
		 1.0f,  1.0f, -1.0f, // top-right of right
		 1.0f,  1.0f,  1.0f, // top-left of right
		 1.0f, -1.0f,  1.0f, // bottom-left of right
		 1.0f, -1.0f, -1.0f, // bottom-right of right

		 // back
		 1.0f,  1.0f, -1.0f, // top-right of back
		-1.0f,  1.0f, -1.0f, // top-left of back
		-1.0f, -1.0f, -1.0f, // bottom-left of back
		 1.0f, -1.0f, -1.0f, // bottom-right of back

		// left
		-1.0f,  1.0f,  1.0f, // top-right of left
		-1.0f,  1.0f, -1.0f, // top-left of left
		-1.0f, -1.0f, -1.0f, // bottom-left of left
		-1.0f, -1.0f,  1.0f, // bottom-right of left

		 // top
		 1.0f,  1.0f, -1.0f, // top-right of top
		-1.0f,  1.0f, -1.0f, // top-left of top
		-1.0f,  1.0f,  1.0f, // bottom-left of top
		 1.0f,  1.0f,  1.0f, // bottom-right of top

		 // bottom
		 1.0f, -1.0f,  1.0f, // top-right of bottom
		-1.0f, -1.0f,  1.0f, // top-left of bottom
		-1.0f, -1.0f, -1.0f, // bottom-left of bottom
		 1.0f, -1.0f, -1.0f, // bottom-right of bottom
	};

	GLfloat cube_texcoords_AMC[] =
	{
		// front
		1.0f, 1.0f, // top-right of front
		0.0f, 1.0f, // top-left of front
		0.0f, 0.0f, // bottom-left of front
		1.0f, 0.0f, // bottom-right of front

		// right
		1.0f, 1.0f, // top-right of right
		0.0f, 1.0f, // top-left of right
		0.0f, 0.0f, // bottom-left of right
		1.0f, 0.0f, // bottom-right of right

		// back
		1.0f, 1.0f, // top-right of back
		0.0f, 1.0f, // top-left of back
		0.0f, 0.0f, // bottom-left of back
		1.0f, 0.0f, // bottom-right of back

		// left
		1.0f, 1.0f, // top-right of left
		0.0f, 1.0f, // top-left of left
		0.0f, 0.0f, // bottom-left of left
		1.0f, 0.0f, // bottom-right of left

		// top
		1.0f, 1.0f, // top-right of top
		0.0f, 1.0f, // top-left of top
		0.0f, 0.0f, // bottom-left of top
		1.0f, 0.0f, // bottom-right of top

		// bottom
		1.0f, 1.0f, // top-right of bottom
		0.0f, 1.0f, // top-left of bottom
		0.0f, 0.0f, // bottom-left of bottom
		1.0f, 0.0f, // bottom-right of bottom
	};

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_cube_AMC);
	glBindVertexArray(vao_cube_AMC);

	// VBO (Vertex Buffer Object) For Position
	glGenBuffers(1, &vbo_position_cube_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_position_cube_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(cube_position_AMC), cube_position_AMC, GL_STATIC_DRAW);
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

	// VBO (Vertex Buffer Object) For Cube Texcoord
	glGenBuffers(1, &vbo_texcoord_cube_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_texcoord_cube_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(cube_texcoords_AMC), cube_texcoords_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_TEXCOORD,
		2,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXCOORD);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glBindVertexArray(0);

	// Tell OpenGL to Enable Texture
	glEnable(GL_TEXTURE_2D);
    
    // Step - 2 : For Depth Enable
    glClearDepth(1.0f);         // Compulsory
    glEnable(GL_DEPTH_TEST);    // Compulsory
    glDepthFunc(GL_LEQUAL);     // Compulsory

    // Set The Clear Color Of Window To White
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);

	// initialize_cube ortho mat
	perspectiveProjectionMatrix_cube_AMC = vmath::mat4::identity();

    [self resize_cube:WIN_WIDTH :WIN_HEIGHT];                            // resize(WIN_WIDTH, WIN_HEIGHT); change mm

	// =================== FBO Releated Code ===================================
	if ([self createFBO:FBO_WIDTH :FBO_HEIGHT] == TRUE)
	{
		bFboResult_AMC = [self initialize_sphere:FBO_WIDTH :FBO_HEIGHT];
	}
    
    return(0);
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
}

-(BOOL)initialize_sphere:(GLint)textureWidth_AMC :(GLint)textureHeight_AMC
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

    // Vertex Shader
	const GLchar* vertexShaderSourceCode_AMC =
		"#version 410 core" \
		"\n" \
		"in vec4 aPosition;" \
		"in vec3 aNormal;" \
		"uniform mat4 uModelMatrix;" \
		"uniform mat4 uViewMatrix;" \
		"uniform mat4 uProjectionMatrix;" \
		"uniform vec3 uLightAmbientOne;" \
		"uniform vec3 uLightDiffuseOne;" \
		"uniform vec3 uLightSpecularOne;" \
		"uniform vec4 uLightPositionOne;" \
        "uniform vec3 uLightAmbientTwo;" \
		"uniform vec3 uLightDiffuseTwo;" \
		"uniform vec3 uLightSpecularTwo;" \
		"uniform vec4 uLightPositionTwo;" \
        "uniform vec3 uLightAmbientThree;" \
		"uniform vec3 uLightDiffuseThree;" \
		"uniform vec3 uLightSpecularThree;" \
		"uniform vec4 uLightPositionThree;" \
		"uniform vec3 uMaterialAmbient;" \
		"uniform vec3 uMaterialDiffuse;" \
		"uniform vec3 uMaterialSpecular;" \
		"uniform float uMaterialShininess;" \
		"out vec3 oTransformedNormals;" \
		"out vec3 oLightDirectionOne;" \
        "out vec3 oLightDirectionTwo;" \
        "out vec3 oLightDirectionThree;" \
		"out vec3 oViewerVector;" \
		"uniform int uKeyPressed;" \
		"out vec3 oPhong_ADS_Light;" \
		"void main(void)" \
		"{" \
			"if(uKeyPressed == 1)" \
			"{" \
                "vec4 eyeCoordinates = uViewMatrix * uModelMatrix * aPosition;" \
                "vec3 transformedNormals = normalize(mat3(uViewMatrix * uModelMatrix) * aNormal);" \
                "vec3 viewerVector = normalize(-eyeCoordinates.xyz);" \
                "vec3 ambientLightOne = uLightAmbientOne * uMaterialAmbient;" \
                "vec3 lightDirectionOne = normalize(vec3(uLightPositionOne - eyeCoordinates));" \
                "vec3 diffuseLightOne = uLightDiffuseOne * uMaterialDiffuse * max(dot(lightDirectionOne, transformedNormals), 0.0);" \
                "vec3 reflectionVectorOne = reflect(-lightDirectionOne, transformedNormals);" \
                "vec3 specularLightOne = uLightSpecularOne * uMaterialSpecular * pow(max(dot(reflectionVectorOne, viewerVector), 0.0), uMaterialShininess);" \
                "vec3 ambientLightTwo = uLightAmbientTwo * uMaterialAmbient;" \
                "vec3 lightDirectionTwo = normalize(vec3(uLightPositionTwo - eyeCoordinates));" \
                "vec3 diffuseLightTwo = uLightDiffuseTwo * uMaterialDiffuse * max(dot(lightDirectionTwo, transformedNormals), 0.0);" \
                "vec3 reflectionVectorTwo = reflect(-lightDirectionTwo, transformedNormals);" \
                "vec3 specularLightTwo = uLightSpecularTwo * uMaterialSpecular * pow(max(dot(reflectionVectorTwo, viewerVector), 0.0), uMaterialShininess);" \
                "vec3 ambientLightThree = uLightAmbientThree * uMaterialAmbient;" \
                "vec3 lightDirectionThree = normalize(vec3(uLightPositionThree - eyeCoordinates));" \
                "vec3 diffuseLightThree = uLightDiffuseThree * uMaterialDiffuse * max(dot(lightDirectionThree, transformedNormals), 0.0);" \
                "vec3 reflectionVectorThree = reflect(-lightDirectionThree, transformedNormals);" \
                "vec3 specularLightThree = uLightSpecularThree * uMaterialSpecular * pow(max(dot(reflectionVectorThree, viewerVector), 0.0), uMaterialShininess);" \
                "oPhong_ADS_Light = ambientLightOne + diffuseLightOne + specularLightOne + ambientLightTwo + diffuseLightTwo + specularLightTwo + ambientLightThree + diffuseLightThree + specularLightThree;" \
			"}" \
			"else if(uKeyPressed == 2)" \
			"{" \
                "vec4 eyeCoordinates = uViewMatrix * uModelMatrix * aPosition;" \
                "oTransformedNormals = mat3(uViewMatrix * uModelMatrix) * aNormal;" \
                "oLightDirectionOne = vec3(uLightPositionOne) - eyeCoordinates.xyz;" \
                "oLightDirectionTwo = vec3(uLightPositionTwo) - eyeCoordinates.xyz;" \
                "oLightDirectionThree = vec3(uLightPositionThree) - eyeCoordinates.xyz;" \
                "oViewerVector = -eyeCoordinates.xyz;" \
			"}" \
			"else" \
			"{" \
                "oTransformedNormals = vec3(0.0, 0.0, 0.0);" \
                "oLightDirectionOne = vec3(0.0, 0.0, 0.0);" \
                "oLightDirectionTwo = vec3(0.0, 0.0, 0.0);" \
                "oLightDirectionThree = vec3(0.0, 0.0, 0.0);" \
                "oViewerVector = vec3(0.0, 0.0, 0.0);" \
			"}" \
			"gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix * aPosition;" \
		"}";

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
		[self uninitialize_sphere];
        [self release];
        [NSApp terminate:self];
	}

	// Fragment Shader
	const GLchar* fragmentShaderSourceCode_AMC =
		"#version 410 core" \
		"\n" \
		"in vec3 oPhong_ADS_Light;" \
		"in vec3 oTransformedNormals;" \
		"in vec3 oLightDirectionOne;" \
        "in vec3 oLightDirectionTwo;" \
        "in vec3 oLightDirectionThree;" \
		"in vec3 oViewerVector;" \
		"uniform vec3 uLightAmbientOne;" \
		"uniform vec3 uLightDiffuseOne;" \
		"uniform vec3 uLightSpecularOne;" \
        "uniform vec3 uLightAmbientTwo;" \
		"uniform vec3 uLightDiffuseTwo;" \
		"uniform vec3 uLightSpecularTwo;" \
        "uniform vec3 uLightAmbientThree;" \
		"uniform vec3 uLightDiffuseThree;" \
		"uniform vec3 uLightSpecularThree;" \
		"uniform vec3 uMaterialAmbient;" \
		"uniform vec3 uMaterialDiffuse;" \
		"uniform vec3 uMaterialSpecular;" \
		"uniform float uMaterialShininess;" \
		"uniform int uKeyPressed;" \
		"out vec4 FragColor;" \
		"void main(void)" \
		"{" \
			"if(uKeyPressed == 1)" \
			"{" \
				"FragColor = vec4(oPhong_ADS_Light, 1.0);" \
			"}" \
			"else if(uKeyPressed == 2)" \
			"{" \
				"vec3 Phong_ADS_Light;" \
                "vec3 normalizedTransformedNormals = normalize(oTransformedNormals);" \
                "vec3 normalizedViewerVector = normalize(oViewerVector);" \
                "vec3 normalizedLightDirectionOne = normalize(oLightDirectionOne);" \
                "vec3 ambientLightOne = uLightAmbientOne * uMaterialAmbient;" \
                "vec3 diffuseLightOne = uLightDiffuseOne * uMaterialDiffuse * max(dot(normalizedTransformedNormals, normalizedLightDirectionOne), 0.0);" \
                "vec3 reflectionVectorOne = reflect(-normalizedLightDirectionOne, normalizedTransformedNormals);" \
                "vec3 specularLightOne = uLightSpecularOne * uMaterialSpecular * pow(max(dot(reflectionVectorOne, normalizedViewerVector), 0.0), uMaterialShininess);" \
                "vec3 normalizedLightDirectionTwo = normalize(oLightDirectionTwo);" \
                "vec3 ambientLightTwo = uLightAmbientTwo * uMaterialAmbient;" \
                "vec3 diffuseLightTwo = uLightDiffuseTwo * uMaterialDiffuse * max(dot(normalizedTransformedNormals, normalizedLightDirectionTwo), 0.0);" \
                "vec3 reflectionVectorTwo = reflect(-normalizedLightDirectionTwo, normalizedTransformedNormals);" \
                "vec3 specularLightTwo = uLightSpecularTwo * uMaterialSpecular * pow(max(dot(reflectionVectorTwo, normalizedViewerVector), 0.0), uMaterialShininess);" \
                "vec3 normalizedLightDirectionThree = normalize(oLightDirectionThree);" \
                "vec3 ambientLightThree = uLightAmbientThree * uMaterialAmbient;" \
                "vec3 diffuseLightThree = uLightDiffuseThree * uMaterialDiffuse * max(dot(normalizedTransformedNormals, normalizedLightDirectionThree), 0.0);" \
                "vec3 reflectionVectorThree = reflect(-normalizedLightDirectionThree, normalizedTransformedNormals);" \
                "vec3 specularLightThree = uLightSpecularThree * uMaterialSpecular * pow(max(dot(reflectionVectorThree, normalizedViewerVector), 0.0), uMaterialShininess);" \
                "Phong_ADS_Light = ambientLightOne + diffuseLightOne + specularLightOne + ambientLightTwo + diffuseLightTwo + specularLightTwo + ambientLightThree + diffuseLightThree + specularLightThree;" \
				"FragColor = vec4(Phong_ADS_Light, 1.0);" \
			"}" \
			"else" \
			"{" \
				"FragColor = vec4(1.0, 1.0, 1.0, 1.0);" \
			"}" \
		"}";

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
		[self uninitialize_sphere];                                            // Change In mm
        [self release];                                                 // Change In mm
        [NSApp terminate:self];                                         // Change In mm
	}

	// Shader Program
	shaderProgramObject_sphere_AMC = glCreateProgram();
	glAttachShader(shaderProgramObject_sphere_AMC, vertexShaderObject_AMC);
	glAttachShader(shaderProgramObject_sphere_AMC, fragmentShaderObject_AMC);

	glBindAttribLocation(shaderProgramObject_sphere_AMC, AMC_ATTRIBUTE_POSITION, "aPosition");
    glBindAttribLocation(shaderProgramObject_sphere_AMC, AMC_ATTRIBUTE_NORMAL, "aNormal");

	glLinkProgram(shaderProgramObject_sphere_AMC);

	status_AMC = 0;
	infoLogLength_AMC = 0;
	szInfoLog_AMC = NULL;

	glGetProgramiv(shaderProgramObject_sphere_AMC, GL_LINK_STATUS, &status_AMC);

	if (status_AMC == GL_FALSE)
	{
		glGetProgramiv(shaderProgramObject_sphere_AMC, GL_INFO_LOG_LENGTH, &infoLogLength_AMC);
		if (infoLogLength_AMC > 0)
		{
			szInfoLog_AMC = (GLchar*)malloc(infoLogLength_AMC);
			if (szInfoLog_AMC != NULL)
			{
				glGetProgramInfoLog(shaderProgramObject_sphere_AMC, infoLogLength_AMC, NULL, szInfoLog_AMC);
				fprintf(gpFile_AMC, "Shader Program Linking Error LOG : %s\n", szInfoLog_AMC);
				free(szInfoLog_AMC);
				szInfoLog_AMC = NULL;
			}
		}
		[self uninitialize_sphere];                                            // Change In mm
        [self release];                                                 // Change In mm
        [NSApp terminate:self];                                         // Change In mm
	}

	// Get Shader Uniform Locations
	// Get Shader Uniform Locations
	modelMatrixUniform_sphere_AMC = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uModelMatrix");
	viewMatrixUniform_sphere_AMC = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uViewMatrix");
	projectionMatrixUniform_sphere_AMC = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uProjectionMatrix");

	lightAmbientUniform_sphere_AMC[0] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightAmbientOne");
	lightDiffuseUniform_sphere_AMC[0] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightDiffuseOne");
	lightSpecularUniform_sphere_AMC[0] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightSpecularOne");
	lightPositionUniform_sphere_AMC[0] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightPositionOne");

	lightAmbientUniform_sphere_AMC[1] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightAmbientTwo");
	lightDiffuseUniform_sphere_AMC[1] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightDiffuseTwo");
	lightSpecularUniform_sphere_AMC[1] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightSpecularTwo");
	lightPositionUniform_sphere_AMC[1] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightPositionTwo");

	lightAmbientUniform_sphere_AMC[2] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightAmbientThree");
	lightDiffuseUniform_sphere_AMC[2] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightDiffuseThree");
	lightSpecularUniform_sphere_AMC[2] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightSpecularThree");
	lightPositionUniform_sphere_AMC[2] = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uLightPositionThree");

	materialAmbientUniform_sphere_AMC = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uMaterialAmbient");
	materialDiffuseUniform_sphere_AMC = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uMaterialDiffuse");
	materialSpecularUniform_sphere_AMC = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uMaterialSpecular");
	materialShininessUniform_sphere_AMC = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uMaterialShininess");

	keyPressedUniform_sphere_AMC = glGetUniformLocation(shaderProgramObject_sphere_AMC, "uKeyPressed");


    Sphere *sphere = [[Sphere alloc]init];
    [sphere getSphereVertexData:sphere_vertices_AMC :sphere_normals_AMC :sphere_texcoords_AMC :sphere_elements_AMC];
    
    gNumVertices_AMC = [sphere getNumberOfSphereVertices];
    gNumElements_AMC = [sphere getNumberOfSphereElements];

	// ======================================= SPHERE VAO ================================================

	// VAO (Vertex Array Object)
	glGenVertexArrays(1, &vao_sphere_AMC);
	glBindVertexArray(vao_sphere_AMC);

	// VBO (Vertex Buffer Object) For Sphere Position
	glGenBuffers(1, &vbo_position_sphere_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_position_sphere_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_vertices_AMC), sphere_vertices_AMC, GL_STATIC_DRAW);
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

	// VBO (Vertex Buffer Object) For Normal
	glGenBuffers(1, &vbo_normals_sphere_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_normals_sphere_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_normals_AMC), sphere_normals_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_NORMAL,
		3,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_NORMAL);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Texture (This VBO added for future use not used in any of the Lights assignments)
	glGenBuffers(1, &vbo_texcoord_sphere_AMC);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_texcoord_sphere_AMC);
	glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_texcoords_AMC), sphere_texcoords_AMC, GL_STATIC_DRAW);
	glVertexAttribPointer(
		AMC_ATTRIBUTE_TEXCOORD,
		2,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXCOORD);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	// VBO (Vertex Buffer Object) For Elements
	glGenBuffers(1, &vbo_element_sphere_AMC);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(sphere_elements_AMC), sphere_elements_AMC, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

	glBindVertexArray(0);
    
    // Step - 2 : For Depth Enable
    glClearDepth(1.0f);         // Compulsory
    glEnable(GL_DEPTH_TEST);    // Compulsory
    glDepthFunc(GL_LEQUAL);     // Compulsory

    // Set The Clear Color Of Window To Black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

	light_sphere_AMC[0].ambient_sphere_AMC = vec3(0.0f, 0.0f, 0.0f);
	light_sphere_AMC[1].ambient_sphere_AMC = vec3(0.0f, 0.0f, 0.0f);
	light_sphere_AMC[2].ambient_sphere_AMC = vec3(0.0f, 0.0f, 0.0f);

	light_sphere_AMC[0].diffuse_sphere_AMC = vec3(1.0f, 0.0f, 0.0f);
	light_sphere_AMC[1].diffuse_sphere_AMC = vec3(0.0f, 0.0f, 1.0f);
	light_sphere_AMC[2].diffuse_sphere_AMC = vec3(0.0f, 1.0f, 0.0f);

	light_sphere_AMC[0].speculer_sphere_AMC = vec3(1.0f, 0.0f, 0.0f);
	light_sphere_AMC[1].speculer_sphere_AMC = vec3(0.0f, 0.0f, 1.0f);
	light_sphere_AMC[2].speculer_sphere_AMC = vec3(0.0f, 1.0f, 0.0f);

	light_sphere_AMC[0].position_sphere_AMC = vec4(-2.0f, 0.0f, 0.0f, 1.0f);
	light_sphere_AMC[1].position_sphere_AMC = vec4(2.0f, 0.0f, 0.0f, 1.0f);
	light_sphere_AMC[2].position_sphere_AMC = vec4(0.0f, 0.0f, 0.0f, 1.0f);

	// initialize_sphere ortho mat
	perspectiveProjectionMatrix_sphere_AMC = vmath::mat4::identity();

    [self resize_sphere:WIN_WIDTH :WIN_HEIGHT];                            // resize_sphere(WIN_WIDTH, WIN_HEIGHT); change mm
    
    return(TRUE);
}

-(BOOL)createFBO:(GLint)textureWidth_AMC :(GLint)textureHeight_AMC
{
	// Variable Declarations
	GLint maxRenderBufferSize_AMC;

	// Check capacity of Render Buffer
	glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE, &maxRenderBufferSize_AMC);

	if (maxRenderBufferSize_AMC < textureWidth_AMC || maxRenderBufferSize_AMC < textureHeight_AMC)
	{
		fprintf(gpFile_AMC, "Texture Size Overflow ...\n");
		return(FALSE);
	}

	// Create Custom Frame Buffer
	glGenFramebuffers(1, &fbo_AMC);
	glBindFramebuffer(GL_FRAMEBUFFER, fbo_AMC);

	// Create Texture For FBO In Which We Are Going To Render 2nd Scene i.e. Sphere
	glGenTextures(1, &textureFBO_AMC);
	glBindTexture(GL_TEXTURE_2D, textureFBO_AMC);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

	glTexImage2D(
		GL_TEXTURE_2D,
		0,
		GL_RGB,
		textureWidth_AMC,
		textureHeight_AMC,
		0,
		GL_RGB,
		GL_UNSIGNED_SHORT_5_6_5,	// 5+6+5 = 16 (For Mobile Compatibility)
		NULL						// No Data
	);

	// Attach Above Texture To Framebuffer At Default ColorAttachment-0
	glFramebufferTexture2D(
		GL_FRAMEBUFFER,
		GL_COLOR_ATTACHMENT0,
		GL_TEXTURE_2D,
		textureFBO_AMC,
		0							// MipMap Level
	);

	// Now Create Render Buffer To Hold Depth Of Custom FBO
	glGenRenderbuffers(1, &rbo_AMC);
	glBindRenderbuffer(
		GL_RENDERBUFFER,			// GL_DRAW_RENDERBUFFER can use for more specific
		rbo_AMC
	);

	// Set storage of above renderbuffer of texture size for depth
	glRenderbufferStorage(
		GL_RENDERBUFFER, 
		GL_DEPTH_COMPONENT16,		// Why 16 ? .. 16 can work on Mobile as well as Desktop (Relevant with 5+6+5 above)
		textureWidth_AMC, 
		textureHeight_AMC
	);

	// Attach Above Depth Releated Render Buffer To FBO at DepthAttchment
	glFramebufferRenderbuffer(
		GL_FRAMEBUFFER,
		GL_DEPTH_ATTACHMENT,
		GL_RENDERBUFFER,
		rbo_AMC
	);

	// Check the FrameBuffer Status Success or Not
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		fprintf(gpFile_AMC, "FrameBuffer Creation Status Is Not Complete.\n");
		return(FALSE);
	}

	// Unbind With The FrameBuffer
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	return(TRUE);
}

-(void)resize_cube:(int)width_AMC :(int)height_AMC
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    if(height_AMC <= 0)
    {
        height_AMC = 1;
    }

	winWidth_AMC = width_AMC;
	winHeight_AMC = height_AMC;
    
    glViewport(0, 0, (GLsizei)width_AMC, (GLsizei)height_AMC);

	// Set perspective projection matrix
	perspectiveProjectionMatrix_cube_AMC = vmath::perspective(   // glFrustum()
		45.0f,                                              // Field Of View (fovy) Radian considered
		(GLfloat)width_AMC / (GLfloat)height_AMC,           // Aspect Ratio
		0.1f,                                               // Near standered Value
		100.0f                                              // Far Standered Value
	);
}

-(void)resize_sphere:(int)width_AMC :(int)height_AMC
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    if(height_AMC <= 0)
    {
        height_AMC = 1;
    }
    
    glViewport(0, 0, (GLsizei)width_AMC, (GLsizei)height_AMC);

	// Set perspective projection matrix
	perspectiveProjectionMatrix_sphere_AMC = vmath::perspective(   // glFrustum()
		45.0f,                                              // Field Of View (fovy) Radian considered
		(GLfloat)width_AMC / (GLfloat)height_AMC,           // Aspect Ratio
		0.1f,                                               // Near standered Value
		100.0f                                              // Far Standered Value
	);
}

-(void)display_cube
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

	// =================================== Render FBO Scene ====================================
	if (bFboResult_AMC == TRUE)
	{
		[self display_sphere:FBO_WIDTH :FBO_HEIGHT];
		[self update_sphere];
	}

	// Call Resize Cube Again To Compenset The Change By display_sphere()
	[self resize_cube:winWidth_AMC :winHeight_AMC];
	glViewport(winWidth_AMC/2, winHeight_AMC/2, (GLsizei)winWidth_AMC, (GLsizei)winHeight_AMC);

	// Reset The Color To White To Compenset The Chnage Done By display_sphere()
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);

	// EXISTING ...

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                                     // Step-3 Depth

	glUseProgram(shaderProgramObject_cube_AMC);

	// =============================== CUBE ===================================
	mat4 modelViewMatrix_AMC = mat4::identity();

	mat4 translationMatrix_AMC = mat4::identity();
	translationMatrix_AMC = vmath::translate(0.0f, 0.0f, -4.0f);

	mat4 scaleMatrix_AMC = mat4::identity();
	scaleMatrix_AMC = vmath::scale(0.75f, 0.75f, 0.75f);

	mat4 rotationMatrix1_AMC = mat4::identity();
	rotationMatrix1_AMC = vmath::rotate(angle_cube_AMC, 1.0f, 0.0f, 0.0f);

	mat4 rotationMatrix2_AMC = mat4::identity();
	rotationMatrix2_AMC = vmath::rotate(angle_cube_AMC, 0.0f, 1.0f, 0.0f);

	mat4 rotationMatrix3_AMC = mat4::identity();
	rotationMatrix3_AMC = vmath::rotate(angle_cube_AMC, 0.0f, 0.0f, 1.0f);

	mat4 rotationMatrix_AMC = rotationMatrix1_AMC * rotationMatrix2_AMC * rotationMatrix3_AMC;

	modelViewMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC * rotationMatrix_AMC; // here order of multiplication is VVIMP.
	mat4 modelViewProjectionMatrix_AMC = perspectiveProjectionMatrix_cube_AMC * modelViewMatrix_AMC; // here order of multiplication is VVIMP.

	// Push above MVP into vertex shhadr's MVP uniform
	glUniformMatrix4fv(mvpMatrixUniform_cube_AMC, 1, GL_FALSE, modelViewProjectionMatrix_AMC);

	// For Texture
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, textureFBO_AMC);	// Here all sphere releated scene is rendering
	glUniform1i(textureSamplerUniform_cube_AMC, 0); // Tell uniformSampler in fragment shader which numbered texture

	glBindVertexArray(vao_cube_AMC);

	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	glDrawArrays(GL_TRIANGLE_FAN, 4, 4);
	glDrawArrays(GL_TRIANGLE_FAN, 8, 4);
	glDrawArrays(GL_TRIANGLE_FAN, 12, 4);
	glDrawArrays(GL_TRIANGLE_FAN, 16, 4);
	glDrawArrays(GL_TRIANGLE_FAN, 20, 4);

	glBindVertexArray(0);

	glBindTexture(GL_TEXTURE_2D, 0);

	glUseProgram(0);
}

-(void)display_sphere:(GLint)textureWidth_AMC :(GLint)textureHeight_AMC
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

	// =================================== FBO Related Code ====================================
	// Bind With FBO
	glBindFramebuffer(GL_FRAMEBUFFER, fbo_AMC);

	// Call resize_sphere()
	[self resize_sphere:textureWidth_AMC :textureHeight_AMC];

	// Reset The Color To Black To Compenset The Change Done By display_cube()
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

	// EXISTING ...

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                                     // Step-3 Depth

	glUseProgram(shaderProgramObject_sphere_AMC);

	if (bLightningEnabled_sphere_AMC == TRUE)
	{
		light_sphere_AMC[0].position_sphere_AMC[0] = 0.0f;
		light_sphere_AMC[0].position_sphere_AMC[1] = 5.0f * (float)sin(lightAngleZero_sphere_AMC);
		light_sphere_AMC[0].position_sphere_AMC[2] = 5.0f * (float)cos(lightAngleZero_sphere_AMC);
		light_sphere_AMC[0].position_sphere_AMC[3] = 1.0f;

		light_sphere_AMC[1].position_sphere_AMC[0] = 5.0f * (float)sin(lightAngleOne_sphere_AMC);
		light_sphere_AMC[1].position_sphere_AMC[1] = 0.0f;
		light_sphere_AMC[1].position_sphere_AMC[2] = 5.0f * (float)cos(lightAngleOne_sphere_AMC);
		light_sphere_AMC[1].position_sphere_AMC[3] = 1.0f;

		light_sphere_AMC[2].position_sphere_AMC[0] = 5.0f * (float)sin(lightAngleTwo_sphere_AMC);
		light_sphere_AMC[2].position_sphere_AMC[1] = 5.0f * (float)cos(lightAngleTwo_sphere_AMC);
		light_sphere_AMC[2].position_sphere_AMC[2] = 0.0f;
		light_sphere_AMC[2].position_sphere_AMC[3] = 1.0f;
	}

	// =========================================== SPHERE ========================================================

	mat4 translationMatrix_AMC = mat4::identity();
	translationMatrix_AMC = vmath::translate(0.0f, 0.0f, -2.0f);

	mat4 modelMatrix_AMC = translationMatrix_AMC;
	mat4 viewMatrix_AMC = mat4::identity();

	// Push above MVP into vertex shhadr's MVP uniform

	glUniformMatrix4fv(modelMatrixUniform_sphere_AMC, 1, GL_FALSE, modelMatrix_AMC);
	glUniformMatrix4fv(viewMatrixUniform_sphere_AMC, 1, GL_FALSE, viewMatrix_AMC);
	glUniformMatrix4fv(projectionMatrixUniform_sphere_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_sphere_AMC);

	if (bLightningEnabled_sphere_AMC == TRUE)
	{
		if (isPerFragmentChoosed_sphere_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_sphere_AMC, 2);

			glUniform3fv(lightAmbientUniform_sphere_AMC[0], 1, light_sphere_AMC[0].ambient_sphere_AMC);
			glUniform3fv(lightDiffuseUniform_sphere_AMC[0], 1, light_sphere_AMC[0].diffuse_sphere_AMC);
			glUniform3fv(lightSpecularUniform_sphere_AMC[0], 1, light_sphere_AMC[0].speculer_sphere_AMC);
			glUniform4fv(lightPositionUniform_sphere_AMC[0], 1, light_sphere_AMC[0].position_sphere_AMC);

			glUniform3fv(lightAmbientUniform_sphere_AMC[1], 1, light_sphere_AMC[1].ambient_sphere_AMC);
			glUniform3fv(lightDiffuseUniform_sphere_AMC[1], 1, light_sphere_AMC[1].diffuse_sphere_AMC);
			glUniform3fv(lightSpecularUniform_sphere_AMC[1], 1, light_sphere_AMC[1].speculer_sphere_AMC);
			glUniform4fv(lightPositionUniform_sphere_AMC[1], 1, light_sphere_AMC[1].position_sphere_AMC);

			glUniform3fv(lightAmbientUniform_sphere_AMC[2], 1, light_sphere_AMC[2].ambient_sphere_AMC);
			glUniform3fv(lightDiffuseUniform_sphere_AMC[2], 1, light_sphere_AMC[2].diffuse_sphere_AMC);
			glUniform3fv(lightSpecularUniform_sphere_AMC[2], 1, light_sphere_AMC[2].speculer_sphere_AMC);
			glUniform4fv(lightPositionUniform_sphere_AMC[2], 1, light_sphere_AMC[2].position_sphere_AMC);

			glUniform3fv(materialAmbientUniform_sphere_AMC, 1, materialAmbient_sphere_AMC);
			glUniform3fv(materialDiffuseUniform_sphere_AMC, 1, materialDiffuse_sphere_AMC);
			glUniform3fv(materialSpecularUniform_sphere_AMC, 1, materialSpecular_sphere_AMC);
			glUniform1f(materialShininessUniform_sphere_AMC, materialShininess_sphere_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_sphere_AMC, 1);

			glUniform3fv(lightAmbientUniform_sphere_AMC[0], 1, light_sphere_AMC[0].ambient_sphere_AMC);
			glUniform3fv(lightDiffuseUniform_sphere_AMC[0], 1, light_sphere_AMC[0].diffuse_sphere_AMC);
			glUniform3fv(lightSpecularUniform_sphere_AMC[0], 1, light_sphere_AMC[0].speculer_sphere_AMC);
			glUniform4fv(lightPositionUniform_sphere_AMC[0], 1, light_sphere_AMC[0].position_sphere_AMC);

			glUniform3fv(lightAmbientUniform_sphere_AMC[1], 1, light_sphere_AMC[1].ambient_sphere_AMC);
			glUniform3fv(lightDiffuseUniform_sphere_AMC[1], 1, light_sphere_AMC[1].diffuse_sphere_AMC);
			glUniform3fv(lightSpecularUniform_sphere_AMC[1], 1, light_sphere_AMC[1].speculer_sphere_AMC);
			glUniform4fv(lightPositionUniform_sphere_AMC[1], 1, light_sphere_AMC[1].position_sphere_AMC);

			glUniform3fv(lightAmbientUniform_sphere_AMC[2], 1, light_sphere_AMC[2].ambient_sphere_AMC);
			glUniform3fv(lightDiffuseUniform_sphere_AMC[2], 1, light_sphere_AMC[2].diffuse_sphere_AMC);
			glUniform3fv(lightSpecularUniform_sphere_AMC[2], 1, light_sphere_AMC[2].speculer_sphere_AMC);
			glUniform4fv(lightPositionUniform_sphere_AMC[2], 1, light_sphere_AMC[2].position_sphere_AMC);

			glUniform3fv(materialAmbientUniform_sphere_AMC, 1, materialAmbient_sphere_AMC);
			glUniform3fv(materialDiffuseUniform_sphere_AMC, 1, materialDiffuse_sphere_AMC);
			glUniform3fv(materialSpecularUniform_sphere_AMC, 1, materialSpecular_sphere_AMC);
			glUniform1f(materialShininessUniform_sphere_AMC, materialShininess_sphere_AMC);
		}
	}
	else
	{
		glUniform1i(keyPressedUniform_sphere_AMC, 0);
	}

	glBindVertexArray(vao_sphere_AMC); // VAO Binding

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
	glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

	glBindVertexArray(0); // VAO UnBinding

	glUseProgram(0);

	// Unbind With The Custom FrameBuffer
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

-(void)update_cube
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

	angle_cube_AMC = angle_cube_AMC - 1.0;

	if (angle_cube_AMC <= 0.0f)
	{
		angle_cube_AMC = angle_cube_AMC + 360.0f;
	}
}

-(void)update_sphere
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

	if (bLightningEnabled_sphere_AMC == TRUE)
	{
		lightAngleZero_sphere_AMC = lightAngleZero_sphere_AMC + 0.1f;
		if (lightAngleZero_sphere_AMC >= 360.0f)
		{
			lightAngleZero_sphere_AMC = lightAngleZero_sphere_AMC - 360.0f;
		}

		lightAngleOne_sphere_AMC = lightAngleOne_sphere_AMC + 0.1f;
		if (lightAngleOne_sphere_AMC >= 360.0f)
		{
			lightAngleOne_sphere_AMC = lightAngleOne_sphere_AMC - 360.0f;
		}

		lightAngleTwo_sphere_AMC = lightAngleTwo_sphere_AMC + 0.1f;
		if (lightAngleTwo_sphere_AMC >= 360.0f)
		{
			lightAngleTwo_sphere_AMC = lightAngleTwo_sphere_AMC - 360.0f;
		}
	}
}

-(void)uninitialize_cube
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

	[self uninitialize_sphere];

    if (shaderProgramObject_cube_AMC)
	{
		glUseProgram(shaderProgramObject_cube_AMC);

		GLint numShaders_AMC = 0;
		glGetProgramiv(shaderProgramObject_cube_AMC, GL_ATTACHED_SHADERS, &numShaders_AMC);

		if (numShaders_AMC > 0)
		{
			GLuint* pShaders_AMC = (GLuint*)malloc(numShaders_AMC * sizeof(GLuint));
			if (pShaders_AMC != NULL)
			{
				glGetAttachedShaders(shaderProgramObject_cube_AMC, numShaders_AMC, NULL, pShaders_AMC);
				for (GLint i = 0; i < numShaders_AMC; i++)
				{
					glDetachShader(shaderProgramObject_cube_AMC, pShaders_AMC[i]);
					glDeleteShader(pShaders_AMC[i]);
					pShaders_AMC[i] = 0;
				}
				free(pShaders_AMC);
				pShaders_AMC = NULL;
			}
		}

		glUseProgram(0);
		glDeleteProgram(shaderProgramObject_cube_AMC);
		shaderProgramObject_cube_AMC = 0;
	}

	// Delete VBO (Vertex Buffer Object) for texture
	if (vbo_texcoord_cube_AMC)
	{
		glDeleteBuffers(1, &vbo_texcoord_cube_AMC);
		vbo_texcoord_cube_AMC = 0;
	}

    // Delete VBO (Vertex Buffer Object) for position
	if (vbo_position_cube_AMC)
	{
		glDeleteBuffers(1, &vbo_position_cube_AMC);
		vbo_position_cube_AMC = 0;
	}

	// Delete VAO (Vertex Array Object)
	if (vao_cube_AMC)
	{
		glDeleteVertexArrays(1, &vao_cube_AMC);
		vao_cube_AMC = 0;
	}

	// Delete Textures
	if (textureFBO_AMC)
	{
		glDeleteTextures(1, &textureFBO_AMC);
		textureFBO_AMC = 0;
	}

	// Delete Render Buffer
	if (rbo_AMC)
	{
		glDeleteRenderbuffers(1, &rbo_AMC);
		rbo_AMC = 0;
	}

	// Delete Frame Buffer
	if (fbo_AMC)
	{
		glDeleteFramebuffers(1, &fbo_AMC);
		fbo_AMC = 0;
	}
}

-(void)uninitialize_sphere
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

    if (shaderProgramObject_sphere_AMC)
	{
		glUseProgram(shaderProgramObject_sphere_AMC);

		GLint numShaders_AMC = 0;
		glGetProgramiv(shaderProgramObject_sphere_AMC, GL_ATTACHED_SHADERS, &numShaders_AMC);

		if (numShaders_AMC > 0)
		{
			GLuint* pShaders_AMC = (GLuint*)malloc(numShaders_AMC * sizeof(GLuint));
			if (pShaders_AMC != NULL)
			{
				glGetAttachedShaders(shaderProgramObject_sphere_AMC, numShaders_AMC, NULL, pShaders_AMC);
				for (GLint i = 0; i < numShaders_AMC; i++)
				{
					glDetachShader(shaderProgramObject_sphere_AMC, pShaders_AMC[i]);
					glDeleteShader(pShaders_AMC[i]);
					pShaders_AMC[i] = 0;
				}
				free(pShaders_AMC);
				pShaders_AMC = NULL;
			}
		}

		glUseProgram(0);
		glDeleteProgram(shaderProgramObject_sphere_AMC);
		shaderProgramObject_sphere_AMC = 0;
	}

	// ================= SPHERE ====================
	// Delete VBO (Vertex Buffer Object) for Elements
	if (vbo_element_sphere_AMC)
	{
		glDeleteBuffers(1, &vbo_element_sphere_AMC);
		vbo_element_sphere_AMC = 0;
	}
	// Delete VBO (Vertex Buffer Object) for Texcoords
	if (vbo_texcoord_sphere_AMC)
	{
		glDeleteBuffers(1, &vbo_texcoord_sphere_AMC);
		vbo_texcoord_sphere_AMC = 0;
	}
	// Delete VBO (Vertex Buffer Object) for Normals
	if (vbo_normals_sphere_AMC)
	{
		glDeleteBuffers(1, &vbo_normals_sphere_AMC);
		vbo_normals_sphere_AMC = 0;
	}
	// Delete VBO (Vertex Buffer Object) for Position
	if (vbo_position_sphere_AMC)
	{
		glDeleteBuffers(1, &vbo_position_sphere_AMC);
		vbo_position_sphere_AMC = 0;
	}
	// Delete VAO (Vertex Array Object)
	if (vao_sphere_AMC)
	{
		glDeleteVertexArrays(1, &vao_sphere_AMC);
		vao_sphere_AMC = 0;
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
            [[self window]toggleFullScreen: self];
            break;
            
		case 'L':
		case 'l':
			if (bLightningEnabled_sphere_AMC == FALSE)
			{
				bLightningEnabled_sphere_AMC = TRUE;
				isPerFragmentChoosed_sphere_AMC = FALSE;
			}
			else
			{
				bLightningEnabled_sphere_AMC = FALSE;
			}
			break;

		case 'F':
		case 'f':
			isPerFragmentChoosed_sphere_AMC = TRUE;
			break;

		case 'V':
		case 'v':
			isPerFragmentChoosed_sphere_AMC = FALSE;
			break;

		case 'Q':
		case 'q':
			[self uninitialize_sphere];
            [self release];
            [NSApp terminate: self];
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
    [self uninitialize_cube];
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
