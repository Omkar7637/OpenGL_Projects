#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <QuartzCore/CVDisplayLink.h>                            // Core Video Display Link
#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "Sphere.h"

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
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_NORMAL,
    AMC_ATTRIBUTE_TEXCOORDS
};

GLfloat lightAmbient_AMC[] = { 0.1f, 0.1f, 0.1f, 1.0f }; 	// Grey Ambient Light
GLfloat lightDiffuse_AMC[] = { 1.0f, 1.0f, 1.0f, 1.0f }; 	// White Diffuse Light, It decides color intensity of the light
GLfloat lightSpecular_AMC[] = { 1.0f, 1.0f, 1.0f, 1.0f }; 	// White Specular Light
GLfloat lightPosition_AMC[] = { 0.0f, 0.0f, 0.0f, 1.0f };

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
    mat4 perspectiveProjectionMatrix_AMC;       // mat4 is in vmath.h

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

	GLuint modelMatrixUniform_AMC;
	GLuint viewMatrixUniform_AMC;
	GLuint projectionMatrixUniform_AMC;

	// Variables for Light
	GLuint lightAmbientUniform_AMC;
	GLuint lightDiffuseUniform_AMC;
	GLuint lightSpecularUniform_AMC;
	GLuint lightPositionUniform_AMC;

	GLuint materialAmbientUniform_AMC;
	GLuint materialDiffuseUniform_AMC;
	GLuint materialSpecularUniform_AMC;
	GLuint materialShininessUniform_AMC;

	GLuint keyPressedUniform_AMC;

	GLfloat materialAmbiant_AMC[4];
	GLfloat materialDiffuse_AMC[4];
	GLfloat materialSpecular_AMC[4];
	GLfloat materialShininess_AMC;

	GLfloat angleForXRotation_AMC;
	GLfloat angleForYRotation_AMC;
	GLfloat angleForZRotation_AMC;

	BOOL bLightningEnabled_AMC;
	GLuint keyPressed_AMC;
	GLfloat zTranslationForSphere_AMC;
}

-(id)initWithFrame: (NSRect)frame
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    self = [super initWithFrame: frame];
    if (self)
    {
        // Initialization
		angleForXRotation_AMC = 0.0f;
		angleForYRotation_AMC = 0.0f;
		angleForZRotation_AMC = 0.0f;

        bLightningEnabled_AMC = FALSE;
		keyPressed_AMC = 0;
		zTranslationForSphere_AMC = -77.0f;


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
		"#version 410 core" \
		"\n" \
		"in vec4 aPosition;" \
		"in vec3 aNormal;" \
		"uniform mat4 uModelMatrix;" \
		"uniform mat4 uViewMatrix;" \
		"uniform mat4 uProjectionMatrix;" \
		"uniform vec4 uLightPosition;" \
		"uniform int uKeyPressed;" \
		"out vec3 oTransformedNormals;" \
		"out vec3 oLightDirection;" \
		"out vec3 oViewerVector;" \
		"void main(void)" \
		"{" \
		"if(uKeyPressed == 1)" \
		"{" \
		"vec4 eyeCoordinates = uViewMatrix * uModelMatrix * aPosition;" \
		"oTransformedNormals = mat3(uViewMatrix * uModelMatrix) * aNormal;" \
		"oLightDirection = vec3(uLightPosition - eyeCoordinates);" \
		"oViewerVector = -eyeCoordinates.xyz;" \
		"}" \
		"else" \
		"{" \
		"oTransformedNormals = vec3(0.0, 0.0, 0.0);" \
		"oLightDirection = vec3(0.0, 0.0, 0.0);" \
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
		[self uninitialize];
        [self release];
        [NSApp terminate:self];
	}

	// Fragment Shader
	const GLchar* fragmentShaderSourceCode_AMC =
		"#version 410 core" \
		"\n" \
		"in vec3 oTransformedNormals;" \
		"in vec3 oLightDirection;" \
		"in vec3 oViewerVector;" \
		"uniform vec3 uLightAmbient;" \
		"uniform vec3 uLightDiffuse;" \
		"uniform vec3 uLightSpecular;" \
		"uniform vec3 uMaterialAmbient;" \
		"uniform vec3 uMaterialDiffuse;" \
		"uniform vec3 uMaterialSpecular;" \
		"uniform float uMaterialShininess;" \
		"uniform int uKeyPressed;" \
		"out vec4 FragColor;" \
		"void main(void)" \
		"{" \
		"vec3 Phong_ADS_Light;" \
		"if(uKeyPressed == 1)" \
		"{" \
		"vec3 normalizedTransformedNormals = normalize(oTransformedNormals);" \
		"vec3 normalizedLightDirection = normalize(oLightDirection);" \
		"vec3 normalizedViewerVector = normalize(oViewerVector);" \
		"vec3 ambientLight = uLightAmbient * uMaterialAmbient;" \
		"vec3 diffuseLight = uLightDiffuse * uMaterialDiffuse * max(dot(normalizedLightDirection, normalizedTransformedNormals), 0.0);" \
		"vec3 reflectionVector = reflect(-normalizedLightDirection, normalizedTransformedNormals);" \
		"vec3 specularLight = uLightSpecular * uMaterialSpecular * pow(max(dot(reflectionVector, normalizedViewerVector), 0.0), uMaterialShininess);" \
		"Phong_ADS_Light = ambientLight + diffuseLight + specularLight;" \
		"}" \
		"else" \
		"{" \
		"Phong_ADS_Light = vec3(1.0, 1.0, 1.0);" \
		"}" \
		"FragColor = vec4(Phong_ADS_Light, 1.0);" \
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
		[self uninitialize];                                            // Change In mm
        [self release];                                                 // Change In mm
        [NSApp terminate:self];                                         // Change In mm
	}

	// Shader Program
	shaderProgramObject_AMC = glCreateProgram();
	glAttachShader(shaderProgramObject_AMC, vertexShaderObject_AMC);
	glAttachShader(shaderProgramObject_AMC, fragmentShaderObject_AMC);

	glBindAttribLocation(shaderProgramObject_AMC, AMC_ATTRIBUTE_POSITION, "aPosition");
    glBindAttribLocation(shaderProgramObject_AMC, AMC_ATTRIBUTE_NORMAL, "aNormal");

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
	modelMatrixUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uModelMatrix");
	viewMatrixUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uViewMatrix");
	projectionMatrixUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uProjectionMatrix");

	lightAmbientUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uLightAmbient");
	lightDiffuseUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uLightDiffuse");
	lightSpecularUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uLightSpecular");
	lightPositionUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uLightPosition");

	materialAmbientUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uMaterialAmbient");
	materialDiffuseUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uMaterialDiffuse");
	materialSpecularUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uMaterialSpecular");
	materialShininessUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uMaterialShininess");

	keyPressedUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uKeyPressed");

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
		AMC_ATTRIBUTE_TEXCOORDS,
		2,
		GL_FLOAT,
		GL_FALSE,
		0,
		NULL
	);
	glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXCOORDS);
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

    // Set The Clear Color Of Window To Grey
    glClearColor(0.25f, 0.25f, 0.25f, 1.0f);

	// initialize ortho mat
	perspectiveProjectionMatrix_AMC = vmath::mat4::identity();

    [self resize:WIN_WIDTH :WIN_HEIGHT];                            // resize(WIN_WIDTH, WIN_HEIGHT); change mm
    
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

-(void)resize:(int)width_AMC :(int)height_AMC
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    if(height_AMC <= 0)
    {
        height_AMC = 1;
    }
    
    glViewport(0, 0, (GLsizei)width_AMC, (GLsizei)height_AMC);

	// Set perspective projection matrix
	perspectiveProjectionMatrix_AMC = vmath::perspective( 	// glFrustum()
		10.0f, 												// Field Of View (fovy) Radian considered
		(GLfloat)width_AMC / (GLfloat)height_AMC, 			// Aspect Ratio
		0.1f, 												// Near standered Value
		100.0f 												// Far Standered Value
	);
}

-(void)display
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                                     // Step-3 Depth

	glUseProgram(shaderProgramObject_AMC);

	mat4 translationMatrix_AMC = mat4::identity();
	mat4 scaleMatrix_AMC = mat4::identity();
	mat4 modelMatrix_AMC = mat4::identity();
	mat4 viewMatrix_AMC = mat4::identity();

	if (keyPressed_AMC == 1)
	{
		lightPosition_AMC[0] = 0.0f;
		lightPosition_AMC[1] = 180.0f * (float)sin(angleForXRotation_AMC);
		lightPosition_AMC[2] = 180.0f * (float)cos(angleForXRotation_AMC);
		lightPosition_AMC[3] = 1.0f;
	}

	if (keyPressed_AMC == 2)
	{
		lightPosition_AMC[0] = 180.0f * (float)sin(angleForYRotation_AMC);
		lightPosition_AMC[1] = 0.0f;
		lightPosition_AMC[2] = 180.0f * (float)cos(angleForYRotation_AMC);
		lightPosition_AMC[3] = 1.0f;
	}

	if (keyPressed_AMC == 3)
	{
		lightPosition_AMC[0] = 180.0f * (float)sin(angleForZRotation_AMC);
		lightPosition_AMC[1] = 180.0f * (float)cos(angleForZRotation_AMC);
		lightPosition_AMC[2] = 0.0f;
		lightPosition_AMC[3] = 1.0f;
	}

	// =========================================== SPHERE ========================================================

	// =============================== 24 Spheres Initialization START ============================================

	// ======================== First Column Of Precious Stones ================================

	// ***** 1st sphere on 1st column, emerald *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.0215;
		materialAmbiant_AMC[1] = 0.1745;
		materialAmbiant_AMC[2] = 0.0215;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.07568;
		materialDiffuse_AMC[1] = 0.61424;
		materialDiffuse_AMC[2] = 0.07568;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.633;
		materialSpecular_AMC[1] = 0.727811;
		materialSpecular_AMC[2] = 0.633;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.6 * 128;

		translationMatrix_AMC = vmath::translate(-8.0f, 5.5f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

		glBindVertexArray(0);
	}

	// ***** 2nd sphere on 1st column, jade *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.135;
		materialAmbiant_AMC[1] = 0.2225;
		materialAmbiant_AMC[2] = 0.1575;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.54;
		materialDiffuse_AMC[1] = 0.89;
		materialDiffuse_AMC[2] = 0.63;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.316228;
		materialSpecular_AMC[1] = 0.316228;
		materialSpecular_AMC[2] = 0.316228;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.1 * 128;

		translationMatrix_AMC = vmath::translate(-8.0f, 3.4f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 3rd sphere on 1st column, obsidian *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.05375;
		materialAmbiant_AMC[1] = 0.05;
		materialAmbiant_AMC[2] = 0.06625;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.18275;
		materialDiffuse_AMC[1] = 0.17;
		materialDiffuse_AMC[2] = 0.22525;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.332741;
		materialSpecular_AMC[1] = 0.328634;
		materialSpecular_AMC[2] = 0.346435;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.3 * 128;

		translationMatrix_AMC = vmath::translate(-8.0f, 1.3f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 4th sphere on 1st column, pearl *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.25;
		materialAmbiant_AMC[1] = 0.20725;
		materialAmbiant_AMC[2] = 0.20725;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 1.0;
		materialDiffuse_AMC[1] = 0.829;
		materialDiffuse_AMC[2] = 0.829;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.296648;
		materialSpecular_AMC[1] = 0.296648;
		materialSpecular_AMC[2] = 0.296648;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.088 * 128;

		translationMatrix_AMC = vmath::translate(-8.0f, -0.8f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 5th sphere on 1st column, ruby *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.1745;
		materialAmbiant_AMC[1] = 0.01175;
		materialAmbiant_AMC[2] = 0.01175;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.61424;
		materialDiffuse_AMC[1] = 0.04136;
		materialDiffuse_AMC[2] = 0.04136;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.727811;
		materialSpecular_AMC[1] = 0.626959;
		materialSpecular_AMC[2] = 0.626959;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.6 * 128;

		translationMatrix_AMC = vmath::translate(-8.0f, -2.9f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 6th sphere on 1st column, turquoise *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.1;
		materialAmbiant_AMC[1] = 0.18725;
		materialAmbiant_AMC[2] = 0.1745;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.396;
		materialDiffuse_AMC[1] = 0.74151;
		materialDiffuse_AMC[2] = 0.69102;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.297254;
		materialSpecular_AMC[1] = 0.30829;
		materialSpecular_AMC[2] = 0.306678;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.1 * 128;

		translationMatrix_AMC = vmath::translate(-8.0f, -5.0f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}


	// **************************************************************************************************************

	// ======================== Second Column Of Precious Stones ================================

	// ***** 1st sphere on 2nd column, brass *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.329412;
		materialAmbiant_AMC[1] = 0.223529;
		materialAmbiant_AMC[2] = 0.027451;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.780392;
		materialDiffuse_AMC[1] = 0.568627;
		materialDiffuse_AMC[2] = 0.113725;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.992157;
		materialSpecular_AMC[1] = 0.941176;
		materialSpecular_AMC[2] = 0.807843;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.21794872 * 128;

		translationMatrix_AMC = vmath::translate(-3.3f, 5.5f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

		glBindVertexArray(0);
	}

	// ***** 2nd sphere on 2nd column, bronze *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.2125;
		materialAmbiant_AMC[1] = 0.1275;
		materialAmbiant_AMC[2] = 0.054;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.714;
		materialDiffuse_AMC[1] = 0.4284;
		materialDiffuse_AMC[2] = 0.18144;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.393548;
		materialSpecular_AMC[1] = 0.271906;
		materialSpecular_AMC[2] = 0.166721;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.2 * 128;

		translationMatrix_AMC = vmath::translate(-3.3f, 3.4f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 3rd sphere on 2nd column, chrome *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.25;
		materialAmbiant_AMC[1] = 0.25;
		materialAmbiant_AMC[2] = 0.25;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.4;
		materialDiffuse_AMC[1] = 0.4;
		materialDiffuse_AMC[2] = 0.4;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.774597;
		materialSpecular_AMC[1] = 0.774597;
		materialSpecular_AMC[2] = 0.774597;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.6 * 128;

		translationMatrix_AMC = vmath::translate(-3.3f, 1.3f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 4th sphere on 2nd column, copper *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.19125;
		materialAmbiant_AMC[1] = 0.0735;
		materialAmbiant_AMC[2] = 0.0225;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.7038;
		materialDiffuse_AMC[1] = 0.27048;
		materialDiffuse_AMC[2] = 0.0828;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.256777;
		materialSpecular_AMC[1] = 0.137622;
		materialSpecular_AMC[2] = 0.086014;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.1 * 128;

		translationMatrix_AMC = vmath::translate(-3.3f, -0.8f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 5th sphere on 2nd column, gold *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.24725;
		materialAmbiant_AMC[1] = 0.1995;
		materialAmbiant_AMC[2] = 0.0745;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.75164;
		materialDiffuse_AMC[1] = 0.60648;
		materialDiffuse_AMC[2] = 0.22648;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.628281;
		materialSpecular_AMC[1] = 0.555802;
		materialSpecular_AMC[2] = 0.366065;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.4 * 128;

		translationMatrix_AMC = vmath::translate(-3.3f, -2.9f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 6th sphere on 2nd column, silver *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.19225;
		materialAmbiant_AMC[1] = 0.19225;
		materialAmbiant_AMC[2] = 0.19225;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.50754;
		materialDiffuse_AMC[1] = 0.50754;
		materialDiffuse_AMC[2] = 0.50754;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.508273;
		materialSpecular_AMC[1] = 0.508273;
		materialSpecular_AMC[2] = 0.508273;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.4 * 128;

		translationMatrix_AMC = vmath::translate(-3.3f, -5.0f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// **************************************************************************************************************

	// ======================== Thired Column Of Precious Stones ================================

	// ***** 1st sphere on 3rd column, black *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.0;
		materialAmbiant_AMC[1] = 0.0;
		materialAmbiant_AMC[2] = 0.0;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.01;
		materialDiffuse_AMC[1] = 0.01;
		materialDiffuse_AMC[2] = 0.01;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.50;
		materialSpecular_AMC[1] = 0.50;
		materialSpecular_AMC[2] = 0.50;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.25 * 128;

		translationMatrix_AMC = vmath::translate(2.54f, 5.5f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

		glBindVertexArray(0);
	}

	// ***** 2nd sphere on 3rd column, cyan *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.0;
		materialAmbiant_AMC[1] = 0.1;
		materialAmbiant_AMC[2] = 0.06;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.0;
		materialDiffuse_AMC[1] = 0.50980392;
		materialDiffuse_AMC[2] = 0.50980392;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.50196078;
		materialSpecular_AMC[1] = 0.50196078;
		materialSpecular_AMC[2] = 0.50196078;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.25 * 128;

		translationMatrix_AMC = vmath::translate(2.54f, 3.4f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 3rd sphere on 3rd column, green *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.0;
		materialAmbiant_AMC[1] = 0.0;
		materialAmbiant_AMC[2] = 0.0;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.1;
		materialDiffuse_AMC[1] = 0.35;
		materialDiffuse_AMC[2] = 0.1;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.45;
		materialSpecular_AMC[1] = 0.55;
		materialSpecular_AMC[2] = 0.45;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.25 * 128;

		translationMatrix_AMC = vmath::translate(2.54f, 1.3f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 4th sphere on 3rd column, red *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.0;
		materialAmbiant_AMC[1] = 0.0;
		materialAmbiant_AMC[2] = 0.0;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.5;
		materialDiffuse_AMC[1] = 0.0;
		materialDiffuse_AMC[2] = 0.0;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.7;
		materialSpecular_AMC[1] = 0.6;
		materialSpecular_AMC[2] = 0.6;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.25 * 128;

		translationMatrix_AMC = vmath::translate(2.54f, -0.8f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 5th sphere on 3rd column, white *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.0;
		materialAmbiant_AMC[1] = 0.0;
		materialAmbiant_AMC[2] = 0.0;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.55;
		materialDiffuse_AMC[1] = 0.55;
		materialDiffuse_AMC[2] = 0.55;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.70;
		materialSpecular_AMC[1] = 0.70;
		materialSpecular_AMC[2] = 0.70;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.25 * 128;

		translationMatrix_AMC = vmath::translate(2.54f, -2.9f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 6th sphere on 3rd column, yellow plastic *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.0;
		materialAmbiant_AMC[1] = 0.0;
		materialAmbiant_AMC[2] = 0.0;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.5;
		materialDiffuse_AMC[1] = 0.5;
		materialDiffuse_AMC[2] = 0.0;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.60;
		materialSpecular_AMC[1] = 0.60;
		materialSpecular_AMC[2] = 0.50;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.25 * 128;

		translationMatrix_AMC = vmath::translate(2.54f, -5.0f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}


	// ======================== Fourth Column Of Precious Stones ================================

	// ***** 1st sphere on 4th column, black *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.02;
		materialAmbiant_AMC[1] = 0.02;
		materialAmbiant_AMC[2] = 0.02;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.01;
		materialDiffuse_AMC[1] = 0.01;
		materialDiffuse_AMC[2] = 0.01;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.4;
		materialSpecular_AMC[1] = 0.4;
		materialSpecular_AMC[2] = 0.4;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.078125 * 128;

		translationMatrix_AMC = vmath::translate(8.0f, 5.5f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

		glBindVertexArray(0);
	}

	// ***** 2nd sphere on 4th column, cyan *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.0;
		materialAmbiant_AMC[1] = 0.05;
		materialAmbiant_AMC[2] = 0.05;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.4;
		materialDiffuse_AMC[1] = 0.5;
		materialDiffuse_AMC[2] = 0.5;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.04;
		materialSpecular_AMC[1] = 0.7;
		materialSpecular_AMC[2] = 0.7;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.078125 * 128;

		translationMatrix_AMC = vmath::translate(8.0f, 3.4f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 3rd sphere on 4th column, green *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.0;
		materialAmbiant_AMC[1] = 0.05;
		materialAmbiant_AMC[2] = 0.0;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.4;
		materialDiffuse_AMC[1] = 0.5;
		materialDiffuse_AMC[2] = 0.4;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.04;
		materialSpecular_AMC[1] = 0.7;
		materialSpecular_AMC[2] = 0.04;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.078125 * 128;

		translationMatrix_AMC = vmath::translate(8.0f, 1.3f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 4th sphere on 4th column, red *****
	{
		// ambient material
		materialAmbiant_AMC[0] = 0.05;
		materialAmbiant_AMC[1] = 0.0;
		materialAmbiant_AMC[2] = 0.0;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.5;
		materialDiffuse_AMC[1] = 0.4;
		materialDiffuse_AMC[2] = 0.4;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.7;
		materialSpecular_AMC[1] = 0.04;
		materialSpecular_AMC[2] = 0.04;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.078125 * 128;

		translationMatrix_AMC = vmath::translate(8.0f, -0.8f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 5th sphere on 4th column, white *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.05;
		materialAmbiant_AMC[1] = 0.05;
		materialAmbiant_AMC[2] = 0.05;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.5;
		materialDiffuse_AMC[1] = 0.5;
		materialDiffuse_AMC[2] = 0.5;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.7;
		materialSpecular_AMC[1] = 0.7;
		materialSpecular_AMC[2] = 0.7;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.078125 * 128;

		translationMatrix_AMC = vmath::translate(8.0f, -2.9f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	// ***** 6th sphere on 4th column, yellow rubber *****
	{

		// ambient material
		materialAmbiant_AMC[0] = 0.05;
		materialAmbiant_AMC[1] = 0.05;
		materialAmbiant_AMC[2] = 0.0;
		materialAmbiant_AMC[3] = 1.0f;

		// diffuse material
		materialDiffuse_AMC[0] = 0.5;
		materialDiffuse_AMC[1] = 0.5;
		materialDiffuse_AMC[2] = 0.4;
		materialDiffuse_AMC[3] = 1.0f;

		// specular material
		materialSpecular_AMC[0] = 0.7;
		materialSpecular_AMC[1] = 0.7;
		materialSpecular_AMC[2] = 0.04;
		materialSpecular_AMC[3] = 1.0f;

		// shininess
		materialShininess_AMC = 0.078125 * 128;

		translationMatrix_AMC = vmath::translate(8.0f, -5.0f, zTranslationForSphere_AMC);
		scaleMatrix_AMC = vmath::scale(1.5f, 1.5f, 1.5f);
		modelMatrix_AMC = translationMatrix_AMC * scaleMatrix_AMC;

		// Push above MVP into vertex shhadr's MVP uniform

		glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
		glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
		glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

		if (bLightningEnabled_AMC == TRUE)
		{
			glUniform1i(keyPressedUniform_AMC, 1);

			glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
			glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
			glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
			glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

			glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbiant_AMC);
			glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
			glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
			glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
		}
		else
		{
			glUniform1i(keyPressedUniform_AMC, 0);
		}

		glBindVertexArray(vao_sphere_AMC); // VAO Binding

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
		glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0);

		glBindVertexArray(0); // VAO UnBinding
	}

	glUseProgram(0);
}

-(void)myUpdate
{
    // --------------------------------------------------- CODE --------------------------------------------------------------------------

	if (bLightningEnabled_AMC == TRUE)
	{
		if (keyPressed_AMC == 1)
		{
			angleForXRotation_AMC = angleForXRotation_AMC + 0.1f;
			if (angleForXRotation_AMC >= 360)
			{
				angleForXRotation_AMC = angleForXRotation_AMC - 360.0f;
			}
		}

		if (keyPressed_AMC == 2)
		{
			angleForYRotation_AMC = angleForYRotation_AMC + 0.1f;
			if (angleForYRotation_AMC >= 360)
			{
				angleForYRotation_AMC = angleForYRotation_AMC - 360.0f;
			}
		}

		if (keyPressed_AMC == 3)
		{
			angleForZRotation_AMC = angleForZRotation_AMC + 0.1f;
			if (angleForZRotation_AMC >= 360)
			{
				angleForZRotation_AMC = angleForZRotation_AMC - 360.0f;
			}
		}
	}
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
            [self uninitialize];
            [self release];
            [NSApp terminate: self];
            break;
            
        case 'F':
        case 'f':
            [[self window]toggleFullScreen: self];
            break;

		case 'L':
		case 'l':
			if (bLightningEnabled_AMC == FALSE)
			{
				lightPosition_AMC[0] = 0.0f;
				lightPosition_AMC[1] = 0.0f;
				lightPosition_AMC[2] = 0.0f;
				lightPosition_AMC[3] = 1.0f;
				
				keyPressed_AMC = 0;

				angleForXRotation_AMC = 0.0f;
				angleForYRotation_AMC = 0.0f;
				angleForZRotation_AMC = 0.0f;

				bLightningEnabled_AMC = TRUE;
			}
			else
			{
				bLightningEnabled_AMC = FALSE;
			}
			break;

		case 'X':
		case 'x':
			keyPressed_AMC = 1;
			angleForXRotation_AMC = 0.0f; // Reset
			break;
		case 'Y':
		case 'y':
			keyPressed_AMC = 2;
			angleForYRotation_AMC = 0.0f; // Reset
			break;
		case 'Z':
		case 'z':
			keyPressed_AMC = 3;
			angleForZRotation_AMC = 0.0f; // Reset
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
