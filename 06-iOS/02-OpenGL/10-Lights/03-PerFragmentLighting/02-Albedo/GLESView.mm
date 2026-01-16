//
//  MyView.m
//  OpenGLES
//
//  Created by apple on 05/11/24.
//

#import "GLESView.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "Sphere.h"

#import "vmath.h"
using   namespace vmath;

#define WIN_WIDTH   800.0
#define WIN_HEIGHT  600.0

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_NORMAL,
    AMC_ATTRIBUTE_TEXCOORDS
};

GLfloat lightAmbient_AMC[] = { 0.1f, 0.1f, 0.1f, 1.0f }; // Grey Ambient Light
GLfloat lightDiffuse_AMC[] = { 1.0f, 1.0f, 1.0f, 1.0f }; // White Diffuse Light, It decides color intensity of the light
GLfloat lightSpecular_AMC[] = { 1.0f, 1.0f, 1.0f, 1.0f }; // White Specular Light
GLfloat lightPosition_AMC[] = { 100.0f, 100.0f, 100.0f, 1.0f };

GLfloat materialAmbient_AMC[] = { 0.0f, 0.0f, 0.0f, 1.0f };
GLfloat materialDiffuse_AMC[] = { 0.5f, 0.2f, 0.7f, 1.0f };
GLfloat materialSpecular_AMC[] = { 0.7f, 0.7f, 0.7f, 1.0f };
GLfloat materialShininess_AMC = 128.0f;

@implementation GLESView
{
    EAGLContext *eaglContext;
    GLuint customFrameBuffer;
    GLuint colorRenderBuffer;
    GLuint depthRenderBuffer;
    
    id displayLink;     // This Can Be : CADisplayLink *displayLink;
    NSInteger framesPerSecond;
    BOOL isDisplayLink;
    
    GLuint shaderProgramObject_AMC;
    mat4 perspectiveProjectionMatrix_AMC;

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

    // Variables For Light
    GLuint lightAmbientUniform_AMC;
    GLuint lightDiffuseUniform_AMC;
    GLuint lightSpecularUniform_AMC;
    GLuint lightPositionUniform_AMC;

    GLuint materialAmbientUniform_AMC;
    GLuint materialDiffuseUniform_AMC;
    GLuint materialSpecularUniform_AMC;
    GLuint materialShininessUniform_AMC;

    GLuint screenTouchedUniform_AMC;

    // Variables For Events
    BOOL bLightningEnabled_AMC;
    BOOL singleTap_AMC;
    BOOL doubleTab_AMC;
}

-(id)initWithFrame:(CGRect)frame
{
    // Code
    self = [super initWithFrame:frame];
    if (self)
    {
        // Variables Initialization
        bLightningEnabled_AMC = FALSE;
        singleTap_AMC = FALSE;
        doubleTab_AMC = FALSE;
        
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
            [self uninitialize];
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
            [self uninitialize];
            [self release];
            exit(0);
        }
        
        // Initialize Frames Per Second
        framesPerSecond = 60;   // Value 60 Is Recomended From IOS-8.2
        
        // Initialize Display Link Existance Variable
        isDisplayLink = NO;
        
        // Call Our Initialize Method
        int result = [self initialize];
        if (result != 0)
        {
            printf("Initialize() Failed !!!");
            [self uninitialize];
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
    [self display];
    [self update];
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
        [self uninitialize];
        [self release];
        exit(0);
    }
    
    // Call Our Resize Here
    [self resize:width :height];
    
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

-(int)initialize
{
    // Code
    [self printGLInfo];
    
    // Vertex Shader
    const GLchar* vertexShaderSourceCode_AMC =
        "#version 300 core" \
        "\n" \
        "in vec4 aPosition;" \
        "in vec3 aNormal;" \
        "uniform mat4 uModelMatrix;" \
        "uniform mat4 uViewMatrix;" \
        "uniform mat4 uProjectionMatrix;" \
        "uniform vec4 uLightPosition;" \
        "uniform int uScreenTouched;" \
        "out vec3 oTransformedNormals;" \
        "out vec3 oLightDirection;" \
        "out vec3 oViewerVector;" \
        "void main(void)" \
        "{" \
            "if(uScreenTouched == 1)" \
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
                printf("Vertex Shader Compilation Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize];
        [self release];
        exit(0);
    }

    // Fragment Shader
    const GLchar* fragmentShaderSourceCode_AMC =
        "#version 300 core"\
        "\n"\
        "precision highp float;"\
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
        "uniform highp int uScreenTouched;" \
        "out vec4 FragColor;" \
        "void main(void)" \
        "{" \
            "vec3 Phong_ADS_Light;" \
            "if(uScreenTouched == 1)" \
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
                printf("Fragment Shader Compilation Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize];                                            // Change In mm
        [self release];                                                 // Change In mm
        exit(0);
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
                printf("Shader Program Linking Error LOG : %s\n", szInfoLog_AMC);
                free(szInfoLog_AMC);
                szInfoLog_AMC = NULL;
            }
        }
        [self uninitialize];                                            // Change In mm
        [self release];                                                 // Change In mm
        exit(0);
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

    screenTouchedUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uScreenTouched");

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
    glClearDepthf(1.0f);        // Compulsory
    glEnable(GL_DEPTH_TEST);    // Compulsory
    glDepthFunc(GL_LEQUAL);     // Compulsory

    // Set The Clear Color Of Window To Black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    // initialize ortho mat
    perspectiveProjectionMatrix_AMC = vmath::mat4::identity();

    [self resize:WIN_WIDTH :WIN_HEIGHT];
    
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

-(void)resize:(int)width_AMC :(int)height_AMC
{
    // Code
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
    // Code
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                                     // Step-3 Depth
    
    glUseProgram(shaderProgramObject_AMC);

    // =========================================== SPHERE ========================================================

    mat4 translationMatrix_AMC = mat4::identity();
    translationMatrix_AMC = vmath::translate(0.0f, 0.0f, -2.0f);

    mat4 modelMatrix_AMC = translationMatrix_AMC;
    mat4 viewMatrix_AMC = mat4::identity();

    // Push above MVP into vertex shhadr's MVP uniform

    glUniformMatrix4fv(modelMatrixUniform_AMC, 1, GL_FALSE, modelMatrix_AMC);
    glUniformMatrix4fv(viewMatrixUniform_AMC, 1, GL_FALSE, viewMatrix_AMC);
    glUniformMatrix4fv(projectionMatrixUniform_AMC, 1, GL_FALSE, perspectiveProjectionMatrix_AMC);

    if (bLightningEnabled_AMC == TRUE)
    {
        glUniform1i(screenTouchedUniform_AMC, 1);

        glUniform3fv(lightAmbientUniform_AMC, 1, lightAmbient_AMC);
        glUniform3fv(lightDiffuseUniform_AMC, 1, lightDiffuse_AMC);
        glUniform3fv(lightSpecularUniform_AMC, 1, lightSpecular_AMC);
        glUniform4fv(lightPositionUniform_AMC, 1, lightPosition_AMC);

        glUniform3fv(materialAmbientUniform_AMC, 1, materialAmbient_AMC);
        glUniform3fv(materialDiffuseUniform_AMC, 1, materialDiffuse_AMC);
        glUniform3fv(materialSpecularUniform_AMC, 1, materialSpecular_AMC);
        glUniform1f(materialShininessUniform_AMC, materialShininess_AMC);
    }
    else
    {
        glUniform1i(screenTouchedUniform_AMC, 0);
    }

    glBindVertexArray(vao_sphere_AMC);     // VAO Binding

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_AMC);
    glDrawElements(GL_TRIANGLES, gNumElements_AMC, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

    glBindVertexArray(0);                 // VAO UnBinding

    glUseProgram(0);
}

-(void)update
{
    // Code
}

-(void)uninitialize
{
    // Code
    
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
    
    // Delete Depth Render Buffer
    if (depthRenderBuffer)
    {
        glDeleteRenderbuffers(1, &depthRenderBuffer);
        depthRenderBuffer = 0;
    }
    
    // Delete Color Reneder Buffer
    if (colorRenderBuffer)
    {
        glDeleteRenderbuffers(1, &colorRenderBuffer);
        colorRenderBuffer = 0;
    }
    
    // Delete Custom FrameBuffer
    if (customFrameBuffer)
    {
        glDeleteFramebuffers(1, &customFrameBuffer);
        customFrameBuffer = 0;
    }
    
    // Release EAGL Context
    if (eaglContext && [EAGLContext currentContext] == eaglContext)
    {
        [EAGLContext setCurrentContext:nil];
        [eaglContext release];
        eaglContext = nil;
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
    
    if (doubleTab_AMC == FALSE)
    {
        bLightningEnabled_AMC = TRUE;
        doubleTab_AMC = TRUE;
    }
    else
    {
        bLightningEnabled_AMC = FALSE;
        doubleTab_AMC = FALSE;
    }
}

-(void)onSwipe:(UISwipeGestureRecognizer*)gestureRecognizer
{
    // Code
    
    [self uninitialize];
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
    [self uninitialize];
    
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
