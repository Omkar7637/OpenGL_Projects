//
//  MyView.m
//  OpenGLES
//
//  Created by apple on 07/11/24.
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

GLfloat lightAmbient_SAG[] = { 0.1f, 0.1f, 0.1f, 1.0f };     // Grey Ambient Light
GLfloat lightDiffuse_SAG[] = { 1.0f, 1.0f, 1.0f, 1.0f };     // White Diffuse Light, It decides color intensity of the light
GLfloat lightSpecular_SAG[] = { 1.0f, 1.0f, 1.0f, 1.0f };     // White Specular Light
GLfloat lightPosition_SAG[] = { 0.0f, 0.0f, 0.0f, 1.0f };

@implementation GLESView
{
    EAGLContext *eaglContext;
    GLuint customFrameBuffer;
    GLuint colorRenderBuffer;
    GLuint depthRenderBuffer;
    
    id displayLink;     // This Can Be : CADisplayLink *displayLink;
    NSInteger framesPerSecond;
    BOOL isDisplayLink;
    
    GLuint shaderProgramObject_SAG;
    mat4 perspectiveProjectionMatrix_SAG;

    GLuint gNumVertices_SAG;
    GLuint gNumElements_SAG;

    float sphere_vertices_SAG[1146];
    float sphere_normals_SAG[1146];
    float sphere_texcoords_SAG[764];
    unsigned short sphere_elements_SAG[2280];

    GLuint vao_sphere_SAG;
    GLuint vbo_position_sphere_SAG;
    GLuint vbo_normals_sphere_SAG;
    GLuint vbo_texcoord_sphere_SAG;
    GLuint vbo_element_sphere_SAG;

    GLuint modelMatrixUniform_SAG;
    GLuint viewMatrixUniform_SAG;
    GLuint projectionMatrixUniform_SAG;

    // Variables for Light
    GLuint lightAmbientUniform_SAG;
    GLuint lightDiffuseUniform_SAG;
    GLuint lightSpecularUniform_SAG;
    GLuint lightPositionUniform_SAG;

    GLuint materialAmbientUniform_SAG;
    GLuint materialDiffuseUniform_SAG;
    GLuint materialSpecularUniform_SAG;
    GLuint materialShininessUniform_SAG;

    GLuint screenTouchedUniform_SAG;

    GLfloat materialAmbiant_SAG[4];
    GLfloat materialDiffuse_SAG[4];
    GLfloat materialSpecular_SAG[4];
    GLfloat materialShininess_SAG;

    GLfloat angleForXRotation_SAG;
    GLfloat angleForYRotation_SAG;
    GLfloat angleForZRotation_SAG;

    GLuint screenTapped_SAG;
    GLfloat zTranslationForSphere_SAG;

    // Variables For Events
    BOOL bLightningEnabled_SAG;
    int singleTap_SAG;
    BOOL doubleTab_SAG;
}

-(id)initWithFrame:(CGRect)frame
{
    // Code
    self = [super initWithFrame:frame];
    if (self)
    {
        // Variables Initialization
        bLightningEnabled_SAG = FALSE;
        singleTap_SAG = 0;
        doubleTab_SAG = FALSE;
        
        angleForXRotation_SAG = 0.0f;
        angleForYRotation_SAG = 0.0f;
        angleForZRotation_SAG = 0.0f;

        screenTapped_SAG = 0;
        zTranslationForSphere_SAG = -77.0f;
        
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
    const GLchar* vertexShaderSourceCode_SAG =
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

    GLuint vertexShaderObject_SAG = glCreateShader(GL_VERTEX_SHADER); // Creates empty shader object

    // below function is made to receive shader source code
    glShaderSource(
        vertexShaderObject_SAG,
        1, // Number Of Strings passed in 3rd parameter (Can pass multiple strings we passed only one)
        (const GLchar**)&vertexShaderSourceCode_SAG,
        NULL // If multiple strings are there in 3rd param then it will be array of lengths of those multiple strings(We have only one so consider whole string)
    );

    // To compile shader source code(To convert human understandable to m/c i.e. GPU)
    glCompileShader(vertexShaderObject_SAG);

    GLint status_SAG = 0;
    GLint infoLogLength_SAG = 0;
    GLchar* szInfoLog_SAG = NULL;

    // To get Error in our own variable
    glGetShaderiv(vertexShaderObject_SAG, GL_COMPILE_STATUS, &status_SAG);

    if (status_SAG == GL_FALSE)
    {
        glGetShaderiv(vertexShaderObject_SAG, GL_INFO_LOG_LENGTH, &infoLogLength_SAG);
        if (infoLogLength_SAG > 0)
        {
            szInfoLog_SAG = (GLchar*)malloc(infoLogLength_SAG + 1);
            if (szInfoLog_SAG != NULL)
            {
                glGetShaderInfoLog(vertexShaderObject_SAG, infoLogLength_SAG + 1, NULL, szInfoLog_SAG);
                printf("Vertex Shader Compilation Error LOG : %s\n", szInfoLog_SAG);
                free(szInfoLog_SAG);
                szInfoLog_SAG = NULL;
            }
        }
        [self uninitialize];
        [self release];
        exit(0);
    }

    // Fragment Shader
    const GLchar* fragmentShaderSourceCode_SAG =
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

    GLuint fragmentShaderObject_SAG = glCreateShader(GL_FRAGMENT_SHADER);

    glShaderSource(fragmentShaderObject_SAG, 1, (const GLchar**)&fragmentShaderSourceCode_SAG, NULL);

    glCompileShader(fragmentShaderObject_SAG);

    status_SAG = 0;
    infoLogLength_SAG = 0;
    szInfoLog_SAG = NULL;

    glGetShaderiv(fragmentShaderObject_SAG, GL_COMPILE_STATUS, &status_SAG);

    if (status_SAG == GL_FALSE)
    {
        glGetShaderiv(fragmentShaderObject_SAG, GL_INFO_LOG_LENGTH, &infoLogLength_SAG); // GL_SHADER_INFO_LOG_LENGTH
        if (infoLogLength_SAG > 0)
        {
            szInfoLog_SAG = (GLchar*)malloc(infoLogLength_SAG);
            if (szInfoLog_SAG != NULL)
            {
                glGetShaderInfoLog(fragmentShaderObject_SAG, infoLogLength_SAG, NULL, szInfoLog_SAG);
                printf("Fragment Shader Compilation Error LOG : %s\n", szInfoLog_SAG);
                free(szInfoLog_SAG);
                szInfoLog_SAG = NULL;
            }
        }
        [self uninitialize];                                            // Change In mm
        [self release];                                                 // Change In mm
        exit(0);
    }

    // Shader Program
    shaderProgramObject_SAG = glCreateProgram();
    glAttachShader(shaderProgramObject_SAG, vertexShaderObject_SAG);
    glAttachShader(shaderProgramObject_SAG, fragmentShaderObject_SAG);

    glBindAttribLocation(shaderProgramObject_SAG, AMC_ATTRIBUTE_POSITION, "aPosition");
    glBindAttribLocation(shaderProgramObject_SAG, AMC_ATTRIBUTE_NORMAL, "aNormal");

    glLinkProgram(shaderProgramObject_SAG);

    status_SAG = 0;
    infoLogLength_SAG = 0;
    szInfoLog_SAG = NULL;

    glGetProgramiv(shaderProgramObject_SAG, GL_LINK_STATUS, &status_SAG);

    if (status_SAG == GL_FALSE)
    {
        glGetProgramiv(shaderProgramObject_SAG, GL_INFO_LOG_LENGTH, &infoLogLength_SAG);
        if (infoLogLength_SAG > 0)
        {
            szInfoLog_SAG = (GLchar*)malloc(infoLogLength_SAG);
            if (szInfoLog_SAG != NULL)
            {
                glGetProgramInfoLog(shaderProgramObject_SAG, infoLogLength_SAG, NULL, szInfoLog_SAG);
                printf("Shader Program Linking Error LOG : %s\n", szInfoLog_SAG);
                free(szInfoLog_SAG);
                szInfoLog_SAG = NULL;
            }
        }
        [self uninitialize];                                            // Change In mm
        [self release];                                                 // Change In mm
        exit(0);
    }

    // Get Shader Uniform Locations
    modelMatrixUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uModelMatrix");
    viewMatrixUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uViewMatrix");
    projectionMatrixUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uProjectionMatrix");

    lightAmbientUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uLightAmbient");
    lightDiffuseUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uLightDiffuse");
    lightSpecularUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uLightSpecular");
    lightPositionUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uLightPosition");

    materialAmbientUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uMaterialAmbient");
    materialDiffuseUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uMaterialDiffuse");
    materialSpecularUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uMaterialSpecular");
    materialShininessUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uMaterialShininess");

    screenTouchedUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uScreenTouched");

    Sphere *sphere = [[Sphere alloc]init];
    [sphere getSphereVertexData:sphere_vertices_SAG :sphere_normals_SAG :sphere_texcoords_SAG :sphere_elements_SAG];
    
    gNumVertices_SAG = [sphere getNumberOfSphereVertices];
    gNumElements_SAG = [sphere getNumberOfSphereElements];

    // ======================================= SPHERE VAO ================================================

    // VAO (Vertex Array Object)
    glGenVertexArrays(1, &vao_sphere_SAG);
    glBindVertexArray(vao_sphere_SAG);

    // VBO (Vertex Buffer Object) For Sphere Position
    glGenBuffers(1, &vbo_position_sphere_SAG);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_position_sphere_SAG);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_vertices_SAG), sphere_vertices_SAG, GL_STATIC_DRAW);
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
    glGenBuffers(1, &vbo_normals_sphere_SAG);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_normals_sphere_SAG);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_normals_SAG), sphere_normals_SAG, GL_STATIC_DRAW);
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
    glGenBuffers(1, &vbo_texcoord_sphere_SAG);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_texcoord_sphere_SAG);
    glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_texcoords_SAG), sphere_texcoords_SAG, GL_STATIC_DRAW);
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
    glGenBuffers(1, &vbo_element_sphere_SAG);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(sphere_elements_SAG), sphere_elements_SAG, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    glBindVertexArray(0);
    
    // Step - 2 : For Depth Enable
    glClearDepthf(1.0f);        // Compulsory
    glEnable(GL_DEPTH_TEST);    // Compulsory
    glDepthFunc(GL_LEQUAL);     // Compulsory

    // Set The Clear Color Of Window To Grey
    glClearColor(0.25f, 0.25f, 0.25f, 1.0f);

    // initialize ortho mat
    perspectiveProjectionMatrix_SAG = vmath::mat4::identity();

    [self resize:WIN_WIDTH :WIN_HEIGHT];
    
    return(0);
}

-(void)printGLInfo
{
    // Variable Declarations
    GLint i_SAG;
    GLint numExtensions_SAG;

    // Code
    printf(":::::::::::::::::::::::::::::::::::::::::::::::\n");
    printf("           OpenGL INFORMATION\n");
    printf(":::::::::::::::::::::::::::::::::::::::::::::::\n");
    printf("OpenGL Vendor      : %s\n",        glGetString(GL_VENDOR));
    printf("OpenGL Renderer    : %s\n",        glGetString(GL_RENDERER));
    printf("OpenGL Version     : %s\n",        glGetString(GL_VERSION));
    printf("GLSL Version       : %s\n",        glGetString(GL_SHADING_LANGUAGE_VERSION));

    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions_SAG);
    for (i_SAG = 0; i_SAG < numExtensions_SAG; i_SAG++)
    {
        printf("%s\n", glGetStringi(GL_EXTENSIONS, i_SAG));
    }
 
    printf(":::::::::::::::::::::::::::::::::::::::::::::::\n");
}

-(void)resize:(int)width_SAG :(int)height_SAG
{
    // Code
    if(height_SAG <= 0)
    {
        height_SAG = 1;
    }
    
    glViewport(0, 0, (GLsizei)width_SAG, (GLsizei)height_SAG);
    
    // Set perspective projection matrix
    perspectiveProjectionMatrix_SAG = vmath::perspective(     // glFrustum()
        10.0f,                                                 // Field Of View (fovy) Radian considered
        (GLfloat)width_SAG / (GLfloat)height_SAG,             // Aspect Ratio
        0.1f,                                                 // Near standered Value
        100.0f                                                 // Far Standered Value
    );
}

-(void)display
{
    // Code
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                                     // Step-3 Depth
    
    glUseProgram(shaderProgramObject_SAG);

    mat4 translationMatrix_SAG = mat4::identity();
    mat4 scaleMatrix_SAG = mat4::identity();
    mat4 modelMatrix_SAG = mat4::identity();
    mat4 viewMatrix_SAG = mat4::identity();

    if (screenTapped_SAG == 1)
    {
        lightPosition_SAG[0] = 0.0f;
        lightPosition_SAG[1] = 180.0f * (float)sin(angleForXRotation_SAG);
        lightPosition_SAG[2] = 180.0f * (float)cos(angleForXRotation_SAG);
        lightPosition_SAG[3] = 1.0f;
    }

    if (screenTapped_SAG == 2)
    {
        lightPosition_SAG[0] = 180.0f * (float)sin(angleForYRotation_SAG);
        lightPosition_SAG[1] = 0.0f;
        lightPosition_SAG[2] = 180.0f * (float)cos(angleForYRotation_SAG);
        lightPosition_SAG[3] = 1.0f;
    }

    if (screenTapped_SAG == 3)
    {
        lightPosition_SAG[0] = 180.0f * (float)sin(angleForZRotation_SAG);
        lightPosition_SAG[1] = 180.0f * (float)cos(angleForZRotation_SAG);
        lightPosition_SAG[2] = 0.0f;
        lightPosition_SAG[3] = 1.0f;
    }

    // =========================================== SPHERE ========================================================

    // =============================== 24 Spheres Initialization START ============================================

    // ======================== First Column Of Precious Stones ================================

    // ***** 1st sphere on 1st column, emerald *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.0215;
        materialAmbiant_SAG[1] = 0.1745;
        materialAmbiant_SAG[2] = 0.0215;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.07568;
        materialDiffuse_SAG[1] = 0.61424;
        materialDiffuse_SAG[2] = 0.07568;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.633;
        materialSpecular_SAG[1] = 0.727811;
        materialSpecular_SAG[2] = 0.633;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.6 * 128;

        translationMatrix_SAG = vmath::translate(-8.0f, 5.5f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

        glBindVertexArray(0);
    }

    // ***** 2nd sphere on 1st column, jade *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.135;
        materialAmbiant_SAG[1] = 0.2225;
        materialAmbiant_SAG[2] = 0.1575;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.54;
        materialDiffuse_SAG[1] = 0.89;
        materialDiffuse_SAG[2] = 0.63;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.316228;
        materialSpecular_SAG[1] = 0.316228;
        materialSpecular_SAG[2] = 0.316228;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.1 * 128;

        translationMatrix_SAG = vmath::translate(-8.0f, 3.4f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 3rd sphere on 1st column, obsidian *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.05375;
        materialAmbiant_SAG[1] = 0.05;
        materialAmbiant_SAG[2] = 0.06625;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.18275;
        materialDiffuse_SAG[1] = 0.17;
        materialDiffuse_SAG[2] = 0.22525;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.332741;
        materialSpecular_SAG[1] = 0.328634;
        materialSpecular_SAG[2] = 0.346435;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.3 * 128;

        translationMatrix_SAG = vmath::translate(-8.0f, 1.3f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 4th sphere on 1st column, pearl *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.25;
        materialAmbiant_SAG[1] = 0.20725;
        materialAmbiant_SAG[2] = 0.20725;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 1.0;
        materialDiffuse_SAG[1] = 0.829;
        materialDiffuse_SAG[2] = 0.829;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.296648;
        materialSpecular_SAG[1] = 0.296648;
        materialSpecular_SAG[2] = 0.296648;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.088 * 128;

        translationMatrix_SAG = vmath::translate(-8.0f, -0.8f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 5th sphere on 1st column, ruby *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.1745;
        materialAmbiant_SAG[1] = 0.01175;
        materialAmbiant_SAG[2] = 0.01175;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.61424;
        materialDiffuse_SAG[1] = 0.04136;
        materialDiffuse_SAG[2] = 0.04136;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.727811;
        materialSpecular_SAG[1] = 0.626959;
        materialSpecular_SAG[2] = 0.626959;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.6 * 128;

        translationMatrix_SAG = vmath::translate(-8.0f, -2.9f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 6th sphere on 1st column, turquoise *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.1;
        materialAmbiant_SAG[1] = 0.18725;
        materialAmbiant_SAG[2] = 0.1745;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.396;
        materialDiffuse_SAG[1] = 0.74151;
        materialDiffuse_SAG[2] = 0.69102;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.297254;
        materialSpecular_SAG[1] = 0.30829;
        materialSpecular_SAG[2] = 0.306678;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.1 * 128;

        translationMatrix_SAG = vmath::translate(-8.0f, -5.0f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }


    // **************************************************************************************************************

    // ======================== Second Column Of Precious Stones ================================

    // ***** 1st sphere on 2nd column, brass *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.329412;
        materialAmbiant_SAG[1] = 0.223529;
        materialAmbiant_SAG[2] = 0.027451;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.780392;
        materialDiffuse_SAG[1] = 0.568627;
        materialDiffuse_SAG[2] = 0.113725;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.992157;
        materialSpecular_SAG[1] = 0.941176;
        materialSpecular_SAG[2] = 0.807843;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.21794872 * 128;

        translationMatrix_SAG = vmath::translate(-3.3f, 5.5f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

        glBindVertexArray(0);
    }

    // ***** 2nd sphere on 2nd column, bronze *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.2125;
        materialAmbiant_SAG[1] = 0.1275;
        materialAmbiant_SAG[2] = 0.054;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.714;
        materialDiffuse_SAG[1] = 0.4284;
        materialDiffuse_SAG[2] = 0.18144;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.393548;
        materialSpecular_SAG[1] = 0.271906;
        materialSpecular_SAG[2] = 0.166721;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.2 * 128;

        translationMatrix_SAG = vmath::translate(-3.3f, 3.4f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 3rd sphere on 2nd column, chrome *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.25;
        materialAmbiant_SAG[1] = 0.25;
        materialAmbiant_SAG[2] = 0.25;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.4;
        materialDiffuse_SAG[1] = 0.4;
        materialDiffuse_SAG[2] = 0.4;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.774597;
        materialSpecular_SAG[1] = 0.774597;
        materialSpecular_SAG[2] = 0.774597;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.6 * 128;

        translationMatrix_SAG = vmath::translate(-3.3f, 1.3f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 4th sphere on 2nd column, copper *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.19125;
        materialAmbiant_SAG[1] = 0.0735;
        materialAmbiant_SAG[2] = 0.0225;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.7038;
        materialDiffuse_SAG[1] = 0.27048;
        materialDiffuse_SAG[2] = 0.0828;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.256777;
        materialSpecular_SAG[1] = 0.137622;
        materialSpecular_SAG[2] = 0.086014;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.1 * 128;

        translationMatrix_SAG = vmath::translate(-3.3f, -0.8f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 5th sphere on 2nd column, gold *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.24725;
        materialAmbiant_SAG[1] = 0.1995;
        materialAmbiant_SAG[2] = 0.0745;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.75164;
        materialDiffuse_SAG[1] = 0.60648;
        materialDiffuse_SAG[2] = 0.22648;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.628281;
        materialSpecular_SAG[1] = 0.555802;
        materialSpecular_SAG[2] = 0.366065;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.4 * 128;

        translationMatrix_SAG = vmath::translate(-3.3f, -2.9f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 6th sphere on 2nd column, silver *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.19225;
        materialAmbiant_SAG[1] = 0.19225;
        materialAmbiant_SAG[2] = 0.19225;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.50754;
        materialDiffuse_SAG[1] = 0.50754;
        materialDiffuse_SAG[2] = 0.50754;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.508273;
        materialSpecular_SAG[1] = 0.508273;
        materialSpecular_SAG[2] = 0.508273;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.4 * 128;

        translationMatrix_SAG = vmath::translate(-3.3f, -5.0f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // **************************************************************************************************************

    // ======================== Thired Column Of Precious Stones ================================

    // ***** 1st sphere on 3rd column, black *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.0;
        materialAmbiant_SAG[1] = 0.0;
        materialAmbiant_SAG[2] = 0.0;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.01;
        materialDiffuse_SAG[1] = 0.01;
        materialDiffuse_SAG[2] = 0.01;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.50;
        materialSpecular_SAG[1] = 0.50;
        materialSpecular_SAG[2] = 0.50;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.25 * 128;

        translationMatrix_SAG = vmath::translate(2.54f, 5.5f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

        glBindVertexArray(0);
    }

    // ***** 2nd sphere on 3rd column, cyan *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.0;
        materialAmbiant_SAG[1] = 0.1;
        materialAmbiant_SAG[2] = 0.06;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.0;
        materialDiffuse_SAG[1] = 0.50980392;
        materialDiffuse_SAG[2] = 0.50980392;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.50196078;
        materialSpecular_SAG[1] = 0.50196078;
        materialSpecular_SAG[2] = 0.50196078;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.25 * 128;

        translationMatrix_SAG = vmath::translate(2.54f, 3.4f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 3rd sphere on 3rd column, green *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.0;
        materialAmbiant_SAG[1] = 0.0;
        materialAmbiant_SAG[2] = 0.0;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.1;
        materialDiffuse_SAG[1] = 0.35;
        materialDiffuse_SAG[2] = 0.1;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.45;
        materialSpecular_SAG[1] = 0.55;
        materialSpecular_SAG[2] = 0.45;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.25 * 128;

        translationMatrix_SAG = vmath::translate(2.54f, 1.3f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 4th sphere on 3rd column, red *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.0;
        materialAmbiant_SAG[1] = 0.0;
        materialAmbiant_SAG[2] = 0.0;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.5;
        materialDiffuse_SAG[1] = 0.0;
        materialDiffuse_SAG[2] = 0.0;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.7;
        materialSpecular_SAG[1] = 0.6;
        materialSpecular_SAG[2] = 0.6;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.25 * 128;

        translationMatrix_SAG = vmath::translate(2.54f, -0.8f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 5th sphere on 3rd column, white *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.0;
        materialAmbiant_SAG[1] = 0.0;
        materialAmbiant_SAG[2] = 0.0;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.55;
        materialDiffuse_SAG[1] = 0.55;
        materialDiffuse_SAG[2] = 0.55;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.70;
        materialSpecular_SAG[1] = 0.70;
        materialSpecular_SAG[2] = 0.70;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.25 * 128;

        translationMatrix_SAG = vmath::translate(2.54f, -2.9f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 6th sphere on 3rd column, yellow plastic *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.0;
        materialAmbiant_SAG[1] = 0.0;
        materialAmbiant_SAG[2] = 0.0;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.5;
        materialDiffuse_SAG[1] = 0.5;
        materialDiffuse_SAG[2] = 0.0;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.60;
        materialSpecular_SAG[1] = 0.60;
        materialSpecular_SAG[2] = 0.50;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.25 * 128;

        translationMatrix_SAG = vmath::translate(2.54f, -5.0f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }


    // ======================== Fourth Column Of Precious Stones ================================

    // ***** 1st sphere on 4th column, black *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.02;
        materialAmbiant_SAG[1] = 0.02;
        materialAmbiant_SAG[2] = 0.02;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.01;
        materialDiffuse_SAG[1] = 0.01;
        materialDiffuse_SAG[2] = 0.01;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.4;
        materialSpecular_SAG[1] = 0.4;
        materialSpecular_SAG[2] = 0.4;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.078125 * 128;

        translationMatrix_SAG = vmath::translate(8.0f, 5.5f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

        glBindVertexArray(0);
    }

    // ***** 2nd sphere on 4th column, cyan *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.0;
        materialAmbiant_SAG[1] = 0.05;
        materialAmbiant_SAG[2] = 0.05;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.4;
        materialDiffuse_SAG[1] = 0.5;
        materialDiffuse_SAG[2] = 0.5;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.04;
        materialSpecular_SAG[1] = 0.7;
        materialSpecular_SAG[2] = 0.7;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.078125 * 128;

        translationMatrix_SAG = vmath::translate(8.0f, 3.4f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 3rd sphere on 4th column, green *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.0;
        materialAmbiant_SAG[1] = 0.05;
        materialAmbiant_SAG[2] = 0.0;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.4;
        materialDiffuse_SAG[1] = 0.5;
        materialDiffuse_SAG[2] = 0.4;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.04;
        materialSpecular_SAG[1] = 0.7;
        materialSpecular_SAG[2] = 0.04;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.078125 * 128;

        translationMatrix_SAG = vmath::translate(8.0f, 1.3f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 4th sphere on 4th column, red *****
    {
        // ambient material
        materialAmbiant_SAG[0] = 0.05;
        materialAmbiant_SAG[1] = 0.0;
        materialAmbiant_SAG[2] = 0.0;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.5;
        materialDiffuse_SAG[1] = 0.4;
        materialDiffuse_SAG[2] = 0.4;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.7;
        materialSpecular_SAG[1] = 0.04;
        materialSpecular_SAG[2] = 0.04;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.078125 * 128;

        translationMatrix_SAG = vmath::translate(8.0f, -0.8f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 5th sphere on 4th column, white *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.05;
        materialAmbiant_SAG[1] = 0.05;
        materialAmbiant_SAG[2] = 0.05;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.5;
        materialDiffuse_SAG[1] = 0.5;
        materialDiffuse_SAG[2] = 0.5;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.7;
        materialSpecular_SAG[1] = 0.7;
        materialSpecular_SAG[2] = 0.7;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.078125 * 128;

        translationMatrix_SAG = vmath::translate(8.0f, -2.9f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    // ***** 6th sphere on 4th column, yellow rubber *****
    {

        // ambient material
        materialAmbiant_SAG[0] = 0.05;
        materialAmbiant_SAG[1] = 0.05;
        materialAmbiant_SAG[2] = 0.0;
        materialAmbiant_SAG[3] = 1.0f;

        // diffuse material
        materialDiffuse_SAG[0] = 0.5;
        materialDiffuse_SAG[1] = 0.5;
        materialDiffuse_SAG[2] = 0.4;
        materialDiffuse_SAG[3] = 1.0f;

        // specular material
        materialSpecular_SAG[0] = 0.7;
        materialSpecular_SAG[1] = 0.7;
        materialSpecular_SAG[2] = 0.04;
        materialSpecular_SAG[3] = 1.0f;

        // shininess
        materialShininess_SAG = 0.078125 * 128;

        translationMatrix_SAG = vmath::translate(8.0f, -5.0f, zTranslationForSphere_SAG);
        scaleMatrix_SAG = vmath::scale(1.5f, 1.5f, 1.5f);
        modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG;

        // Push above MVP into vertex shhadr's MVP uniform

        glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
        glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
        glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

        if (bLightningEnabled_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
            glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbiant_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 0);
        }

        glBindVertexArray(vao_sphere_SAG); // VAO Binding

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
        glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0);

        glBindVertexArray(0); // VAO UnBinding
    }

    glUseProgram(0);
}

-(void)update
{
    // Code
    
    if (bLightningEnabled_SAG == TRUE)
    {
        if (screenTapped_SAG == 1)
        {
            angleForXRotation_SAG = angleForXRotation_SAG + 0.1f;
            if (angleForXRotation_SAG >= 360)
            {
                angleForXRotation_SAG = angleForXRotation_SAG - 360.0f;
            }
        }

        if (screenTapped_SAG == 2)
        {
            angleForYRotation_SAG = angleForYRotation_SAG + 0.1f;
            if (angleForYRotation_SAG >= 360)
            {
                angleForYRotation_SAG = angleForYRotation_SAG - 360.0f;
            }
        }

        if (screenTapped_SAG == 3)
        {
            angleForZRotation_SAG = angleForZRotation_SAG + 0.1f;
            if (angleForZRotation_SAG >= 360)
            {
                angleForZRotation_SAG = angleForZRotation_SAG - 360.0f;
            }
        }
    }
}

-(void)uninitialize
{
    // Code
    
    if (shaderProgramObject_SAG)
    {
        glUseProgram(shaderProgramObject_SAG);

        GLint numShaders_SAG = 0;
        glGetProgramiv(shaderProgramObject_SAG, GL_ATTACHED_SHADERS, &numShaders_SAG);

        if (numShaders_SAG > 0)
        {
            GLuint* pShaders_SAG = (GLuint*)malloc(numShaders_SAG * sizeof(GLuint));
            if (pShaders_SAG != NULL)
            {
                glGetAttachedShaders(shaderProgramObject_SAG, numShaders_SAG, NULL, pShaders_SAG);
                for (GLint i = 0; i < numShaders_SAG; i++)
                {
                    glDetachShader(shaderProgramObject_SAG, pShaders_SAG[i]);
                    glDeleteShader(pShaders_SAG[i]);
                    pShaders_SAG[i] = 0;
                }
                free(pShaders_SAG);
                pShaders_SAG = NULL;
            }
        }

        glUseProgram(0);
        glDeleteProgram(shaderProgramObject_SAG);
        shaderProgramObject_SAG = 0;
    }

    // ================= SPHERE ====================
    // Delete VBO (Vertex Buffer Object) for Elements
    if (vbo_element_sphere_SAG)
    {
        glDeleteBuffers(1, &vbo_element_sphere_SAG);
        vbo_element_sphere_SAG = 0;
    }
    // Delete VBO (Vertex Buffer Object) for Texcoords
    if (vbo_texcoord_sphere_SAG)
    {
        glDeleteBuffers(1, &vbo_texcoord_sphere_SAG);
        vbo_texcoord_sphere_SAG = 0;
    }
    // Delete VBO (Vertex Buffer Object) for Normals
    if (vbo_normals_sphere_SAG)
    {
        glDeleteBuffers(1, &vbo_normals_sphere_SAG);
        vbo_normals_sphere_SAG = 0;
    }
    // Delete VBO (Vertex Buffer Object) for Position
    if (vbo_position_sphere_SAG)
    {
        glDeleteBuffers(1, &vbo_position_sphere_SAG);
        vbo_position_sphere_SAG = 0;
    }
    // Delete VAO (Vertex Array Object)
    if (vao_sphere_SAG)
    {
        glDeleteVertexArrays(1, &vao_sphere_SAG);
        vao_sphere_SAG = 0;
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
    singleTap_SAG++;
    if (singleTap_SAG == 1)
    {
        screenTapped_SAG = 1;
    }
    
    if (singleTap_SAG == 2)
    {
        screenTapped_SAG = 2;
    }
    
    if (singleTap_SAG == 3)
    {
        screenTapped_SAG = 3;
        singleTap_SAG = 0;
    }
}

-(void)onDoubleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    // Code
    
    if (doubleTab_SAG == FALSE)
    {
        bLightningEnabled_SAG = TRUE;
        
        singleTap_SAG = 0;
        screenTapped_SAG = 0;
        
        lightPosition_SAG[0] = 0.0f;
        lightPosition_SAG[1] = 0.0f;
        lightPosition_SAG[2] = 0.0f;
        lightPosition_SAG[3] = 1.0f;
        
        angleForXRotation_SAG = 0.0f;
        angleForYRotation_SAG = 0.0f;
        angleForZRotation_SAG = 0.0f;
        
        doubleTab_SAG = TRUE;
    }
    else
    {
        bLightningEnabled_SAG = FALSE;
        singleTap_SAG = 0;
        screenTapped_SAG = 0;
        doubleTab_SAG = FALSE;
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
