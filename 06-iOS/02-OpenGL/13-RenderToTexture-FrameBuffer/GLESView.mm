//
//  MyView.m
//  OpenGLES
//
//  Created by apple on 10/11/24.
//

#import "GLESView.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "Sphere.h"

#import "vmath.h"
using   namespace vmath;

#define WIN_WIDTH   800.0
#define WIN_HEIGHT  600.0

// FBO Releated Macros
#define FBO_WIDTH     512.0
#define FBO_HEIGHT     512.0

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

@implementation GLESView
{
    EAGLContext *eaglContext;
    GLuint customFrameBuffer;
    GLuint colorRenderBuffer;
    GLuint depthRenderBuffer;
    
    id displayLink;     // This Can Be : CADisplayLink *displayLink;
    NSInteger framesPerSecond;
    BOOL isDisplayLink;
    
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

-(id)initWithFrame:(CGRect)frame
{
    // Code
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialize Variables
        winWidth_AMC = 0;
        winHeight_AMC = 0;

        fbo_AMC = 0;
        rbo_AMC = 0;
        textureFBO_AMC = 0;
        bFboResult_AMC = FALSE;
        
        // Set The Background To Black
        [self setBackgroundColor:[UIColor blackColor]];
        
        // *********************** Prparation For OpenGL ********************************
        
        // Step-1: Create EAGL Layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*)[super layer];
        
        // Step-2: Set EAGL layer Properties
        [eaglLayer setOpaque:YES];                      // Property-1
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        [eaglLayer setDrawableProperties:dictionary];   // Property-1
        
        // Step-3: Get EAGLContext
        eaglContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
        if(eaglContext == nil)
        {
            printf("OpenGLES Context Creation Failed !!!");
            [self uninitialize_cube];
            [self release];
            exit(0);
        }
        
        // Step-4: Set This Above Context As Current Context
        [EAGLContext setCurrentContext:eaglContext];
        
        // Step-5: Create Custom Frame Buffer
        glGenFramebuffers(1, &customFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, customFrameBuffer);
        
        // Step-6: Create Color Render Buffer
        glGenRenderbuffers(1, &colorRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
        
        // Step-7: Give Storage To Color Render Buffer By Using IOS Function
        [eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
        
        // Step-8: Assign Above Color Buffer To Custom Frame Buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
        
        // Depth Render Buffer
        // Find Width Of The Color Buffer
        GLint width;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
        
        // Find Height Of The Color Buffer
        GLint height;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
        
        // Step-9: Create And Bind With Render Buffer
        glGenRenderbuffers(1, &depthRenderBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderBuffer);
        
        // Give Storage To Depth Render Buffer By Using OpenGLES Function
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
        
        // Give This Depth Render Buffer To Custom Frame Buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderBuffer);
        
        // Step-10: Check Status Of The Custom Buffer
        GLenum frameBuffer_status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (frameBuffer_status != GL_FRAMEBUFFER_COMPLETE)
        {
            printf("FrameBuffer Status Is Not Complete !!!");
            [self uninitialize_cube];
            [self release];
            exit(0);
        }
        
        // Initialize Frames Per Second
        framesPerSecond = 60;   // Value 60 Is Recomended From IOS-8.2
        
        // Initialize Display Link Existance Variable
        isDisplayLink = NO;
        
        // Call Our Initialize Method
        int result = [self initialize_cube];
        if (result != 0)
        {
            printf("initialize_cube() Failed !!!");
            [self uninitialize_cube];
            [self release];
            exit(0);
        }
        
        // ****************** EVENTS/GESTURE RECOGNIZER **************************
        
        // Step-1: Create Object Of Single Tap Gesture Recognizer
        // Step-2: Set Number Of Taps Required
        // Step-3: Set Number Of Fingers Required
        // Step-4: Set The Delegate As Self
        // Step-5: Add Abov Configured Gesture Recognizer In Self
        
        // ++++++++++++++++++++++++++ Single Tap +++++++++++++++++++++++++++++++++
        
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onSingleTap:)];
        [singleTapGestureRecognizer setNumberOfTapsRequired:1];
        [singleTapGestureRecognizer setNumberOfTouchesRequired:1];
        [singleTapGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:singleTapGestureRecognizer];
        
        // ++++++++++++++++++++++++++ Double Tap +++++++++++++++++++++++++++++++++
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTap:)];
        [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
        [doubleTapGestureRecognizer setNumberOfTouchesRequired:1];
        [doubleTapGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:doubleTapGestureRecognizer];
        
        // Double Tap Should Fail For Two Single Taps
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        
        // +++++++++++++++++++++++++++ Swipe +++++++++++++++++++++++++++++++++++++
        UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(onSwipe:)];
        [swipeGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:swipeGestureRecognizer];
        
        // ++++++++++++++++++++++++++ Long Press +++++++++++++++++++++++++++++++++
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(onLongPress:)];
        [longPressGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:longPressGestureRecognizer];
    }
    return self;
}

// Animation Steps-1 of A.
+(Class)layerClass
{
    // Code
    return [CAEAGLLayer class];
}

//-(void)drawRect:(CGRect)rect
//{
//    // ----------------------------------------------- CODE ----------------------------------------------------------
//}

-(void)drawView:(id)displayLink
{
    // Code
    
    // Step-1: Set Current Context Again
    // Step-2: Bind With the FrameBuffer Again
    // Step-3: Call Display() Here
    // Step-4: Bind With The Color Render Buffer Again
    // Step-5: Present This Color Render Buffer Which Will Internally Do Double Buffering
    
    // Windows: swapBuffers(), Linux: glxSwapBuffers(), Android: requestRender(), WebGL: requestAnimationFrame(), MacOS: CGLFlushDrawable(), IOS: presentRenderBuffer()
    
    [EAGLContext setCurrentContext:eaglContext];
    glBindFramebuffer(GL_FRAMEBUFFER, customFrameBuffer);
    [self display_cube];
    [self update_cube];
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    [eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

// Override lyoutSubviews Method
-(void)layoutSubviews
{
    // Code
    
    // Bind With The ColorRenderBuffer Again
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    
    // Create ColorRenderBuffer Storage Again
    [eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)[self layer]];
    
    // Depth Render Buffer
    // Find Width Of The Color Buffer
    GLint width;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    
    // Find Height Of The Color Buffer
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    // Create And Bind With Render Buffer
    glGenRenderbuffers(1, &depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderBuffer);
    
    // Give Storage To Depth Render Buffer By Using OpenGLES Function
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    
    // Give This Depth Render Buffer To Custom Frame Buffer
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderBuffer);
    
    // Check Status Of The Custom Buffer
    GLenum frameBuffer_status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (frameBuffer_status != GL_FRAMEBUFFER_COMPLETE)
    {
        printf("FrameBuffer Status Is Not Complete (In layoutSubviews()) !!!");
        [self uninitialize_cube];
        [self release];
        exit(0);
    }
    
    // Call Our Resize Here
    [self resize_cube:width :height];
    
    // It Is Recomended That You Should Call drawView() Here Like WarmUp resize()
    [self drawView:displayLink];
}

// startDisplayLink() custom method which will be called by AppDelegate
-(void)startDisplayLink
{
    // Code
    
    if (isDisplayLink == NO)
    {
        // Create DisplayLink
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
        
        // Set Frames Per Second For Display Link
        [displayLink setPreferredFramesPerSecond:framesPerSecond];
        
        // Add This DiplayLink To Our Run Loop
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        // Set isDisplayLink To Yes
        isDisplayLink = YES;
    }
}

// stopDisplayLink() custom method which will be called by AppDelegate
-(void)stopDisplayLink
{
    // Code
    
    if (isDisplayLink == YES)
    {
        // Remove Display Link From RunLoop By Invalidating It
        [displayLink invalidate];
        
        // Set isDisplayLink To NO
        isDisplayLink = NO;
    }
}

-(int)initialize_cube
{
    // Code
    [self printGLInfo];
    
    // Vertex Shader
    const GLchar* vertexShaderSourceCode_AMC =
        "#version 300 core                          "\
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
                printf("Vertex Shader Compilation Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize_cube];
        [self release];
        exit(0);
    }

    // Fragment Shader
    const GLchar* fragmentShaderSourceCode_AMC =
        "#version 300 core                                  "\
        "\n                                                 "\
        "precision highp float;                             "\
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
                printf("Fragment Shader Compilation Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize_cube];                                               // Change In mm
        [self release];                                                         // Change In mm
        exit(0);
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
                printf("Shader Program Linking Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize_cube];                                            // Change In mm
        [self release];                                                 // Change In mm
        exit(0);
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
    glClearDepthf(1.0f);        // Compulsory
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

    // Code
    printf(":::::::::::::::::::::::::::::::::::::::::::::::\n");
    printf("           OpenGL INFORMATION\n");
    printf(":::::::::::::::::::::::::::::::::::::::::::::::\n");
    printf("OpenGL Vendor      : %s\n",        glGetString(GL_VENDOR));
    printf("OpenGL Renderer    : %s\n",        glGetString(GL_RENDERER));
    printf("OpenGL Version     : %s\n",        glGetString(GL_VERSION));
    printf("GLSL Version       : %s\n",        glGetString(GL_SHADING_LANGUAGE_VERSION));

    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions_AMC);
    for (i_AMC = 0; i_AMC < numExtensions_AMC; i_AMC++)
    {
        printf("%s\n", glGetStringi(GL_EXTENSIONS, i_AMC));
    }
 
    printf(":::::::::::::::::::::::::::::::::::::::::::::::\n");
}

-(BOOL)initialize_sphere:(GLint)textureWidth_AMC :(GLint)textureHeight_AMC
{
    // ---Code---------------

    // Vertex Shader
    const GLchar* vertexShaderSourceCode_AMC =
        "#version 300 core" \
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
                printf("Vertex Shader Compilation Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize_sphere];
        [self release];
        exit(0);
    }

    // Fragment Shader
    const GLchar* fragmentShaderSourceCode_AMC =
        "#version 300 core" \
        "\n" \
        "precision highp float;"\
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
        "uniform highp int uKeyPressed;" \
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
                printf("Fragment Shader Compilation Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize_sphere];                                            // Change In mm
        [self release];                                                 // Change In mm
        exit(0);
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
                printf("Shader Program Linking Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize_sphere];                                            // Change In mm
        [self release];                                                 // Change In mm
        exit(0);
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
    glClearDepthf(1.0f);         // Compulsory
    glEnable(GL_DEPTH_TEST);     // Compulsory
    glDepthFunc(GL_LEQUAL);      // Compulsory

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
        printf("Texture Size Overflow ...\n");
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
        GL_UNSIGNED_SHORT_5_6_5,    // 5+6+5 = 16 (For Mobile Compatibility)
        NULL                        // No Data
    );

    // Attach Above Texture To Framebuffer At Default ColorAttachment-0
    glFramebufferTexture2D(
        GL_FRAMEBUFFER,
        GL_COLOR_ATTACHMENT0,
        GL_TEXTURE_2D,
        textureFBO_AMC,
        0                            // MipMap Level
    );

    // Now Create Render Buffer To Hold Depth Of Custom FBO
    glGenRenderbuffers(1, &rbo_AMC);
    glBindRenderbuffer(
        GL_RENDERBUFFER,            // GL_DRAW_RENDERBUFFER can use for more specific
        rbo_AMC
    );

    // Set storage of above renderbuffer of texture size for depth
    glRenderbufferStorage(
        GL_RENDERBUFFER,
        GL_DEPTH_COMPONENT16,        // Why 16 ? .. 16 can work on Mobile as well as Desktop (Relevant with 5+6+5 above)
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
        printf("FrameBuffer Creation Status Is Not Complete.\n");
        return(FALSE);
    }

    // Unbind With The FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    return(TRUE);
}

-(void)resize_cube:(int)width_AMC :(int)height_AMC
{
    // ---Code---------------
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
    // ---Code---------------
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
    // ---Code---------------

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
    glBindTexture(GL_TEXTURE_2D, textureFBO_AMC);    // Here all sphere releated scene is rendering
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
    // ---Code---------------

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
    // ---Code---------------

    angle_cube_AMC = angle_cube_AMC - 1.0;

    if (angle_cube_AMC <= 0.0f)
    {
        angle_cube_AMC = angle_cube_AMC + 360.0f;
    }
}

-(void)update_sphere
{
    // ---Code---------------

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
    // ---Code---------------

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
    // ---Code---------------

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

-(BOOL)becomeFirstResponder
{
    // Code
    return YES;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    // Code
}

-(void)onSingleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    // Code
}

-(void)onDoubleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    // Code
}

-(void)onSwipe:(UISwipeGestureRecognizer*)gestureRecognizer
{
    // Code
    
    [self uninitialize_cube];
    [self release];
    exit(0);
}

-(void)onLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
    // Code
}

-(void)dealloc
{
    // Code
    [super dealloc];
    [self uninitialize_cube];
    
    // Release DisplayLink
    if (displayLink)
    {
        [displayLink invalidate];
        [displayLink stop];
        [displayLink release];
        displayLink = nil;
    }
}

@end
