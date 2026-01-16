//
//  MyView.m
//  OpenGLES
//
//  Created by apple on 10/11/24.
//

#import "GLESView.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

#import "vmath.h"
using   namespace vmath;

#define WIN_WIDTH   800.0
#define WIN_HEIGHT  600.0

enum
{
    AMC_ATTRIBUTE_POSITION = 0,
    AMC_ATTRIBUTE_COLOR,
    AMC_ATTRIBUTE_NORMAL,
    AMC_ATTRIBUTE_TEXCOORD
};

GLfloat lightAmbient_SAG[] = { 0.5f, 0.5f, 0.5f, 1.0f }; // Grey Ambient Light
GLfloat lightDiffuse_SAG[] = { 1.0f, 1.0f, 1.0f, 1.0f }; // White Diffuse Light, It decides color intensity of the light
GLfloat lightSpecular_SAG[] = { 1.0f, 1.0f, 1.0f, 1.0f }; // White Specular Light
GLfloat lightPosition_SAG[] = { 100.0f, 100.0f, 100.0f, 1.0f };

GLfloat materialAmbient_SAG[] = { 0.0f, 0.0f, 0.0f, 1.0f };
GLfloat materialDiffuse_SAG[] = { 0.5f, 0.2f, 0.7f, 1.0f };
GLfloat materialSpecular_SAG[] = { 0.7f, 0.7f, 0.7f, 1.0f };
GLfloat materialShininess_SAG = 128.0f;

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
    mat4 perspectiveProjectionMatrix_SAG;       // mat4 is in vmath.h

    GLuint modelMatrixUniform_SAG;
    GLuint viewMatrixUniform_SAG;
    GLuint projectionMatrixUniform_SAG;

    // ------------------------------- VAO & VBO ---------------------------------
    GLuint vao_SAG;
    GLuint vbo_SAG;

    // -------------------------- Variables For Texture --------------------------
    GLuint textureSamplerUniform_SAG;
    GLuint texture_marble_SAG;

    // --------------------------- Variables for Light ---------------------------
    GLuint lightAmbientUniform_SAG;
    GLuint lightDiffuseUniform_SAG;
    GLuint lightSpecularUniform_SAG;
    GLuint lightPositionUniform_SAG;

    GLuint materialAmbientUniform_SAG;
    GLuint materialDiffuseUniform_SAG;
    GLuint materialSpecularUniform_SAG;
    GLuint materialShininessUniform_SAG;

    GLuint screenTouchedUniform_SAG;

    BOOL bLightningEnabled_SAG;
    BOOL doubleTab_SAG;

    // --------------------------- Global Variable For Rotation ---------------------------
    GLfloat cAngle_SAG;
}

-(id)initWithFrame:(CGRect)frame
{
    // Code
    self = [super initWithFrame:frame];
    if (self)
    {
        // Variable Initialization
        bLightningEnabled_SAG = FALSE;
        doubleTab_SAG = FALSE;
        cAngle_SAG = 0.0f;
        
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
        "#version 300 core"\
        "\n"\
        "in vec4 aPosition;" \
        "in vec4 aColor;" \
        "in vec3 aNormal;" \
        "in vec2 aTexCoord;" \
        "uniform mat4 uModelMatrix;" \
        "uniform mat4 uViewMatrix;" \
        "uniform mat4 uProjectionMatrix;" \
        "uniform vec4 uLightPosition;" \
        "uniform int uScreenTouched;" \
        "out vec3 oTransformedNormals;" \
        "out vec3 oLightDirection;" \
        "out vec3 oViewerVector;" \
        "out vec4 oColor;" \
        "out vec2 oTexCoord;" \
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
            "oColor=aColor;" \
            "oTexCoord=aTexCoord;" \
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
        "in vec4 oColor;" \
        "in vec2 oTexCoord;" \
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
        "uniform sampler2D uTextureSampler;" \
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
            "vec3 tex = vec3(texture(uTextureSampler, oTexCoord));"\
            "FragColor = vec4(tex * vec3(oColor) * Phong_ADS_Light, 1.0);" \
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
    glBindAttribLocation(shaderProgramObject_SAG, AMC_ATTRIBUTE_COLOR, "aColor");
    glBindAttribLocation(shaderProgramObject_SAG, AMC_ATTRIBUTE_TEXCOORD, "aTexCoord");
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

    textureSamplerUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uTextureSampler");

    lightAmbientUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uLightAmbient");
    lightDiffuseUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uLightDiffuse");
    lightSpecularUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uLightSpecular");
    lightPositionUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uLightPosition");

    materialAmbientUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uMaterialAmbient");
    materialDiffuseUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uMaterialDiffuse");
    materialSpecularUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uMaterialSpecular");
    materialShininessUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uMaterialShininess");

    screenTouchedUniform_SAG = glGetUniformLocation(shaderProgramObject_SAG, "uScreenTouched");

    GLfloat cube_PCNT_SAG[] =
    {
        // front
        // position                // color             // normals                // texcoords
         1.0f,  1.0f,  1.0f,    1.0f, 0.0f, 0.0f,     0.0f,  0.0f,  1.0f,    1.0f, 1.0f,
        -1.0f,  1.0f,  1.0f,    1.0f, 0.0f, 0.0f,     0.0f,  0.0f,  1.0f,    0.0f, 1.0f,
        -1.0f, -1.0f,  1.0f,    1.0f, 0.0f, 0.0f,     0.0f,  0.0f,  1.0f,    0.0f, 0.0f,
         1.0f, -1.0f,  1.0f,    1.0f, 0.0f, 0.0f,     0.0f,  0.0f,  1.0f,    1.0f, 0.0f,
                         
        // right
        // position                // color             // normals                // texcoords
         1.0f,  1.0f, -1.0f,    0.0f, 0.0f, 1.0f,     1.0f,  0.0f,  0.0f,    1.0f, 1.0f,
         1.0f,  1.0f,  1.0f,    0.0f, 0.0f, 1.0f,     1.0f,  0.0f,  0.0f,    0.0f, 1.0f,
         1.0f, -1.0f,  1.0f,    0.0f, 0.0f, 1.0f,     1.0f,  0.0f,  0.0f,    0.0f, 0.0f,
         1.0f, -1.0f, -1.0f,    0.0f, 0.0f, 1.0f,     1.0f,  0.0f,  0.0f,    1.0f, 0.0f,
                         
        // back
        // position                // color             // normals                // texcoords
         1.0f,  1.0f, -1.0f,    1.0f, 1.0f, 0.0f,     0.0f,  0.0f, -1.0f,    1.0f, 1.0f,
        -1.0f,  1.0f, -1.0f,    1.0f, 1.0f, 0.0f,     0.0f,  0.0f, -1.0f,    0.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,    1.0f, 1.0f, 0.0f,     0.0f,  0.0f, -1.0f,    0.0f, 0.0f,
         1.0f, -1.0f, -1.0f,    1.0f, 1.0f, 0.0f,     0.0f,  0.0f, -1.0f,    1.0f, 0.0f,
                         
        // left
        // position                // color             // normals                // texcoords
        -1.0f,  1.0f,  1.0f,    1.0f, 0.0f, 1.0f,    -1.0f,  0.0f,  0.0f,    1.0f, 1.0f,
        -1.0f,  1.0f, -1.0f,    1.0f, 0.0f, 1.0f,    -1.0f,  0.0f,  0.0f,    0.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,    1.0f, 0.0f, 1.0f,    -1.0f,  0.0f,  0.0f,    0.0f, 0.0f,
        -1.0f, -1.0f,  1.0f,    1.0f, 0.0f, 1.0f,    -1.0f,  0.0f,  0.0f,    1.0f, 0.0f,
                         
        // top
        // position                // color             // normals                // texcoords
         1.0f,  1.0f, -1.0f,    0.0f, 1.0f, 0.0f,     0.0f,  1.0f,  0.0f,    1.0f, 1.0f,
        -1.0f,  1.0f, -1.0f,    0.0f, 1.0f, 0.0f,     0.0f,  1.0f,  0.0f,    0.0f, 1.0f,
        -1.0f,  1.0f,  1.0f,    0.0f, 1.0f, 0.0f,     0.0f,  1.0f,  0.0f,    0.0f, 0.0f,
         1.0f,  1.0f,  1.0f,    0.0f, 1.0f, 0.0f,     0.0f,  1.0f,  0.0f,    1.0f, 0.0f,
                         
        // bottom
        // position                // color             // normals                // texcoords
         1.0f, -1.0f,  1.0f,    1.0f, 0.5f, 0.0f,     0.0f, -1.0f,  0.0f,    1.0f, 1.0f,
        -1.0f, -1.0f,  1.0f,    1.0f, 0.5f, 0.0f,     0.0f, -1.0f,  0.0f,    0.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,    1.0f, 0.5f, 0.0f,     0.0f, -1.0f,  0.0f,    0.0f, 0.0f,
         1.0f, -1.0f, -1.0f,    1.0f, 0.5f, 0.0f,     0.0f, -1.0f,  0.0f,    1.0f, 0.0f,
    };

    // ======================== CUBE =====================================

    // VAO (Vertex Array Object)
    glGenVertexArrays(1, &vao_SAG);
    glBindVertexArray(vao_SAG);

    // VBO (Vertex Buffer Object)
    glGenBuffers(1, &vbo_SAG);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_SAG);
    glBufferData(GL_ARRAY_BUFFER, 24 * 11 * sizeof(float), cube_PCNT_SAG, GL_STATIC_DRAW);

    // POSITION
    glVertexAttribPointer(
        AMC_ATTRIBUTE_POSITION,
        3,
        GL_FLOAT,
        GL_FALSE,
        11 * sizeof(float),
        (void*)0
    );
    glEnableVertexAttribArray(AMC_ATTRIBUTE_POSITION);

    // COLOR
    glVertexAttribPointer(
        AMC_ATTRIBUTE_COLOR,
        3,
        GL_FLOAT,
        GL_FALSE,
        11 * sizeof(float),
        (void*)(3 * sizeof(float))
    );
    glEnableVertexAttribArray(AMC_ATTRIBUTE_COLOR);

    // NORMALS
    glVertexAttribPointer(
        AMC_ATTRIBUTE_NORMAL,
        3,
        GL_FLOAT,
        GL_FALSE,
        11 * sizeof(float),
        (void*)(6 * sizeof(float))
    );
    glEnableVertexAttribArray(AMC_ATTRIBUTE_NORMAL);

    // TEXCOORDS
    glVertexAttribPointer(
        AMC_ATTRIBUTE_TEXCOORD,
        2,
        GL_FLOAT,
        GL_FALSE,
        11 * sizeof(float),
        (void*)(9 * sizeof(float))
    );
    glEnableVertexAttribArray(AMC_ATTRIBUTE_TEXCOORD);

    glBindBuffer(GL_ARRAY_BUFFER, 0);        // VBO Unbind
    glBindVertexArray(0);                    // VAO Unbind
    
    // Loading Images/ Create Texture
    texture_marble_SAG = [self loadTextureFromImage:@"Marble" :@"bmp"];

    // Tell OpenGL to Enable Texture
    glEnable(GL_TEXTURE_2D);
    
    // Step - 2 : For Depth Enable
    glClearDepthf(1.0f);        // Compulsory
    glEnable(GL_DEPTH_TEST);    // Compulsory
    glDepthFunc(GL_LEQUAL);     // Compulsory

    // Set The Clear Color Of Window To Black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    // initialize ortho mat
    perspectiveProjectionMatrix_SAG = vmath::mat4::identity();

    [self resize:WIN_WIDTH :WIN_HEIGHT];
    
    return(0);
}

-(GLuint)loadTextureFromImage:(NSString*)imageFileName :(NSString*)extension
{
    // ---------------------------------- Code --------------------------------------------

    // Step-1 : Create the NSString Based image file Name.
    NSString *imageFileNameWithPath = [[NSBundle mainBundle]pathForResource:imageFileName ofType:extension];

    // Step-2 : Create NSImage object.
    UIImage *image = [[UIImage alloc]initWithContentsOfFile:imageFileNameWithPath]; //initWithContentsOfFile

    if (image == nil)
    {
        printf("Creating UIImage Object Failed .... \n");
        [self uninitialize];
        [self release];
        exit(0);
    }

    // Step-3 : Create CGImage object from above NSImage Object.
    CGImageRef cgImage = [image CGImage];

    // Step-4 : Get width & height of image using above CGImage.
    int imageWidth = (int)CGImageGetWidth(cgImage);
    int imageHeight = (int)CGImageGetHeight(cgImage);

    // Step-5 : Get CGDataProviderRef from above CGImage.
    CGDataProviderRef imageDataProviderRef = CGImageGetDataProvider(cgImage);

    // Step-6 : Get CFDataRef (CF: Core Foundation) from above CGDataProviderRef.
    CFDataRef imageDataRef = CGDataProviderCopyData(imageDataProviderRef);

    // Step-7 : Get void* format of image data from above CFDataRef.
    const UInt8 *imageData = CFDataGetBytePtr(imageDataRef);

    // Step-8 : Use usual OpenGL function to create Texture like glGenTexture, glBindTexture, glPixelStorei, glTexParameteri, glTexImage2D, glGenerateMipmap.

    // Create OpenGL Texture Using Above imageWidth, imageHeight & imageData
    GLuint texture = 0;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    glGenerateMipmap(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, 0);

    // Step-9 : Call CFRelease to release the CFDataRef that we created in 6th Step.
    CFRelease(imageDataRef);

    return(texture);
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
    perspectiveProjectionMatrix_SAG = vmath::perspective(   // glFrustum()
        45.0f,                                              // Field Of View (fovy) Radian considered
        (GLfloat)width_SAG / (GLfloat)height_SAG,           // Aspect Ratio
        0.1f,                                               // Near standered Value
        100.0f                                              // Far Standered Value
    );
}

-(void)display
{
    // Code
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);                                     // Step-3 Depth
    
    glUseProgram(shaderProgramObject_SAG);

    // =============================== CUBE ===================================
    mat4 viewMatrix_SAG = mat4::identity();
    mat4 modelMatrix_SAG = mat4::identity();

    mat4 translationMatrix_SAG = mat4::identity();
    translationMatrix_SAG = vmath::translate(0.0f, 0.0f, -5.0f);

    mat4 scaleMatrix_SAG = mat4::identity();
    scaleMatrix_SAG = vmath::scale(0.75f, 0.75f, 0.75f);

    mat4 rotationMatrix1_SAG = mat4::identity();
    rotationMatrix1_SAG = vmath::rotate(cAngle_SAG, 1.0f, 0.0f, 0.0f);

    mat4 rotationMatrix2_SAG = mat4::identity();
    rotationMatrix2_SAG = vmath::rotate(cAngle_SAG, 0.0f, 1.0f, 0.0f);

    mat4 rotationMatrix3_SAG = mat4::identity();
    rotationMatrix3_SAG = vmath::rotate(cAngle_SAG, 0.0f, 0.0f, 1.0f);

    mat4 rotationMatrix_SAG = rotationMatrix1_SAG * rotationMatrix2_SAG * rotationMatrix3_SAG;

    modelMatrix_SAG = translationMatrix_SAG * scaleMatrix_SAG * rotationMatrix_SAG; // here order of multiplication is VVIMP.

    // Push above MVP into vertex Shader's MVP uniform
    glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
    glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
    glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

    // For Texture
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture_marble_SAG);
    glUniform1i(textureSamplerUniform_SAG, 0); // Tell uniformSampler in fragment shader which numbered texture

    // For Light
    if (bLightningEnabled_SAG == TRUE)
    {
        glUniform1i(screenTouchedUniform_SAG, 1);

        glUniform3fv(lightAmbientUniform_SAG, 1, lightAmbient_SAG);
        glUniform3fv(lightDiffuseUniform_SAG, 1, lightDiffuse_SAG);
        glUniform3fv(lightSpecularUniform_SAG, 1, lightSpecular_SAG);
        glUniform4fv(lightPositionUniform_SAG, 1, lightPosition_SAG);

        glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbient_SAG);
        glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
        glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
        glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
    }
    else
    {
        glUniform1i(screenTouchedUniform_SAG, 0);
    }

    glBindVertexArray(vao_SAG);

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

-(void)update
{
    // Code
    
    cAngle_SAG = cAngle_SAG - 1.0;

    if (cAngle_SAG <= 0.0f)
    {
        cAngle_SAG = cAngle_SAG + 360.0f;
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

    // Delete VBO (Vertex Buffer Object) for position
    if (vbo_SAG)
    {
        glDeleteBuffers(1, &vbo_SAG);
        vbo_SAG = 0;
    }

    // Delete VAO (Vertex Array Object)
    if (vao_SAG)
    {
        glDeleteVertexArrays(1, &vao_SAG);
        vao_SAG = 0;
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
    
    if (doubleTab_SAG == FALSE)
    {
        bLightningEnabled_SAG = TRUE;
        doubleTab_SAG = TRUE;
    }
    else
    {
        bLightningEnabled_SAG = FALSE;
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
