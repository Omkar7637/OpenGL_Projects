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

struct Light
{
    vec3 ambient_SAG;
    vec3 diffuse_SAG;
    vec3 speculer_SAG;
    vec4 position_SAG;
};
struct Light light_SAG[3];

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

    // Variables For Light
    GLuint lightAmbientUniform_SAG[3];
    GLuint lightDiffuseUniform_SAG[3];
    GLuint lightSpecularUniform_SAG[3];
    GLuint lightPositionUniform_SAG[3];

    GLuint materialAmbientUniform_SAG;
    GLuint materialDiffuseUniform_SAG;
    GLuint materialSpecularUniform_SAG;
    GLuint materialShininessUniform_SAG;

    GLuint screenTouchedUniform_SAG;

    // Light Rotation Variables
    GLfloat lightAngleZero_SAG;
    GLfloat lightAngleOne_SAG;
    GLfloat lightAngleTwo_SAG;

    // Variables For Events
    BOOL bLightningEnabled_SAG;
    BOOL isPerFragmentChoosed_SAG;
    BOOL singleTap_SAG;
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
        isPerFragmentChoosed_SAG = FALSE;
        singleTap_SAG = FALSE;
        doubleTab_SAG = FALSE;
        
        lightAngleZero_SAG = 0.0f;
        lightAngleOne_SAG = 0.0f;
        lightAngleTwo_SAG = 0.0f;
        
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
        "uniform int uScreenTouched;" \
        "out vec3 oPhong_ADS_Light;" \
        "void main(void)" \
        "{" \
            "if(uScreenTouched == 1)" \
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
            "else if(uScreenTouched == 2)" \
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
        "uniform highp int uScreenTouched;" \
        "out vec4 FragColor;" \
        "void main(void)" \
        "{" \
            "if(uScreenTouched == 1)" \
            "{" \
                "FragColor = vec4(oPhong_ADS_Light, 1.0);" \
            "}" \
            "else if(uScreenTouched == 2)" \
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

    lightAmbientUniform_SAG[0] = glGetUniformLocation(shaderProgramObject_SAG, "uLightAmbientOne");
    lightDiffuseUniform_SAG[0] = glGetUniformLocation(shaderProgramObject_SAG, "uLightDiffuseOne");
    lightSpecularUniform_SAG[0] = glGetUniformLocation(shaderProgramObject_SAG, "uLightSpecularOne");
    lightPositionUniform_SAG[0] = glGetUniformLocation(shaderProgramObject_SAG, "uLightPositionOne");

    lightAmbientUniform_SAG[1] = glGetUniformLocation(shaderProgramObject_SAG, "uLightAmbientTwo");
    lightDiffuseUniform_SAG[1] = glGetUniformLocation(shaderProgramObject_SAG, "uLightDiffuseTwo");
    lightSpecularUniform_SAG[1] = glGetUniformLocation(shaderProgramObject_SAG, "uLightSpecularTwo");
    lightPositionUniform_SAG[1] = glGetUniformLocation(shaderProgramObject_SAG, "uLightPositionTwo");

    lightAmbientUniform_SAG[2] = glGetUniformLocation(shaderProgramObject_SAG, "uLightAmbientThree");
    lightDiffuseUniform_SAG[2] = glGetUniformLocation(shaderProgramObject_SAG, "uLightDiffuseThree");
    lightSpecularUniform_SAG[2] = glGetUniformLocation(shaderProgramObject_SAG, "uLightSpecularThree");
    lightPositionUniform_SAG[2] = glGetUniformLocation(shaderProgramObject_SAG, "uLightPositionThree");

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

    // Set The Clear Color Of Window To Black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    light_SAG[0].ambient_SAG = vec3(0.0f, 0.0f, 0.0f);
    light_SAG[1].ambient_SAG = vec3(0.0f, 0.0f, 0.0f);
    light_SAG[2].ambient_SAG = vec3(0.0f, 0.0f, 0.0f);

    light_SAG[0].diffuse_SAG = vec3(1.0f, 0.0f, 0.0f);
    light_SAG[1].diffuse_SAG = vec3(0.0f, 0.0f, 1.0f);
    light_SAG[2].diffuse_SAG = vec3(0.0f, 1.0f, 0.0f);

    light_SAG[0].speculer_SAG = vec3(1.0f, 0.0f, 0.0f);
    light_SAG[1].speculer_SAG = vec3(0.0f, 0.0f, 1.0f);
    light_SAG[2].speculer_SAG = vec3(0.0f, 1.0f, 0.0f);

    light_SAG[0].position_SAG = vec4(-2.0f, 0.0f, 0.0f, 1.0f);
    light_SAG[1].position_SAG = vec4(2.0f, 0.0f, 0.0f, 1.0f);
    light_SAG[2].position_SAG = vec4(0.0f, 0.0f, 0.0f, 1.0f);

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

    if (bLightningEnabled_SAG == TRUE)
    {
        light_SAG[0].position_SAG[0] = 0.0f;
        light_SAG[0].position_SAG[1] = 5.0f * (float)sin(lightAngleZero_SAG);
        light_SAG[0].position_SAG[2] = 5.0f * (float)cos(lightAngleZero_SAG);
        light_SAG[0].position_SAG[3] = 1.0f;

        light_SAG[1].position_SAG[0] = 5.0f * (float)sin(lightAngleOne_SAG);
        light_SAG[1].position_SAG[1] = 0.0f;
        light_SAG[1].position_SAG[2] = 5.0f * (float)cos(lightAngleOne_SAG);
        light_SAG[1].position_SAG[3] = 1.0f;

        light_SAG[2].position_SAG[0] = 5.0f * (float)sin(lightAngleTwo_SAG);
        light_SAG[2].position_SAG[1] = 5.0f * (float)cos(lightAngleTwo_SAG);
        light_SAG[2].position_SAG[2] = 0.0f;
        light_SAG[2].position_SAG[3] = 1.0f;
    }

    // =========================================== SPHERE ========================================================

    mat4 translationMatrix_SAG = mat4::identity();
    translationMatrix_SAG = vmath::translate(0.0f, 0.0f, -2.0f);

    mat4 modelMatrix_SAG = translationMatrix_SAG;
    mat4 viewMatrix_SAG = mat4::identity();

    // Push above MVP into vertex shhadr's MVP uniform

    glUniformMatrix4fv(modelMatrixUniform_SAG, 1, GL_FALSE, modelMatrix_SAG);
    glUniformMatrix4fv(viewMatrixUniform_SAG, 1, GL_FALSE, viewMatrix_SAG);
    glUniformMatrix4fv(projectionMatrixUniform_SAG, 1, GL_FALSE, perspectiveProjectionMatrix_SAG);

    if (bLightningEnabled_SAG == TRUE)
    {
        if (isPerFragmentChoosed_SAG == TRUE)
        {
            glUniform1i(screenTouchedUniform_SAG, 2);

            glUniform3fv(lightAmbientUniform_SAG[0], 1, light_SAG[0].ambient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG[0], 1, light_SAG[0].diffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG[0], 1, light_SAG[0].speculer_SAG);
            glUniform4fv(lightPositionUniform_SAG[0], 1, light_SAG[0].position_SAG);

            glUniform3fv(lightAmbientUniform_SAG[1], 1, light_SAG[1].ambient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG[1], 1, light_SAG[1].diffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG[1], 1, light_SAG[1].speculer_SAG);
            glUniform4fv(lightPositionUniform_SAG[1], 1, light_SAG[1].position_SAG);

            glUniform3fv(lightAmbientUniform_SAG[2], 1, light_SAG[2].ambient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG[2], 1, light_SAG[2].diffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG[2], 1, light_SAG[2].speculer_SAG);
            glUniform4fv(lightPositionUniform_SAG[2], 1, light_SAG[2].position_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbient_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
        else
        {
            glUniform1i(screenTouchedUniform_SAG, 1);

            glUniform3fv(lightAmbientUniform_SAG[0], 1, light_SAG[0].ambient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG[0], 1, light_SAG[0].diffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG[0], 1, light_SAG[0].speculer_SAG);
            glUniform4fv(lightPositionUniform_SAG[0], 1, light_SAG[0].position_SAG);

            glUniform3fv(lightAmbientUniform_SAG[1], 1, light_SAG[1].ambient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG[1], 1, light_SAG[1].diffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG[1], 1, light_SAG[1].speculer_SAG);
            glUniform4fv(lightPositionUniform_SAG[1], 1, light_SAG[1].position_SAG);

            glUniform3fv(lightAmbientUniform_SAG[2], 1, light_SAG[2].ambient_SAG);
            glUniform3fv(lightDiffuseUniform_SAG[2], 1, light_SAG[2].diffuse_SAG);
            glUniform3fv(lightSpecularUniform_SAG[2], 1, light_SAG[2].speculer_SAG);
            glUniform4fv(lightPositionUniform_SAG[2], 1, light_SAG[2].position_SAG);

            glUniform3fv(materialAmbientUniform_SAG, 1, materialAmbient_SAG);
            glUniform3fv(materialDiffuseUniform_SAG, 1, materialDiffuse_SAG);
            glUniform3fv(materialSpecularUniform_SAG, 1, materialSpecular_SAG);
            glUniform1f(materialShininessUniform_SAG, materialShininess_SAG);
        }
    }
    else
    {
        glUniform1i(screenTouchedUniform_SAG, 0);
    }

    glBindVertexArray(vao_sphere_SAG); // VAO Binding

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_element_sphere_SAG);
    glDrawElements(GL_TRIANGLES, gNumElements_SAG, GL_UNSIGNED_SHORT, 0); // 3rd Param is of type Element's Array's Type

    glBindVertexArray(0); // VAO UnBinding

    glUseProgram(0);
}

-(void)update
{
    // Code
    
    if (bLightningEnabled_SAG == TRUE)
    {
        lightAngleZero_SAG = lightAngleZero_SAG + 0.1f;
        if (lightAngleZero_SAG >= 360.0f)
        {
            lightAngleZero_SAG = lightAngleZero_SAG - 360.0f;
        }

        lightAngleOne_SAG = lightAngleOne_SAG + 0.1f;
        if (lightAngleOne_SAG >= 360.0f)
        {
            lightAngleOne_SAG = lightAngleOne_SAG - 360.0f;
        }

        lightAngleTwo_SAG = lightAngleTwo_SAG + 0.1f;
        if (lightAngleTwo_SAG >= 360.0f)
        {
            lightAngleTwo_SAG = lightAngleTwo_SAG - 360.0f;
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
    
    if (singleTap_SAG == FALSE)
    {
        isPerFragmentChoosed_SAG = TRUE;
        singleTap_SAG = TRUE;
    }
    else
    {
        isPerFragmentChoosed_SAG = FALSE;
        singleTap_SAG = FALSE;
    }
}

-(void)onDoubleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    // Code
    
    if (doubleTab_SAG == FALSE)
    {
        bLightningEnabled_SAG = TRUE;
        isPerFragmentChoosed_SAG = FALSE;
        singleTap_SAG = FALSE;
        doubleTab_SAG = TRUE;
    }
    else
    {
        bLightningEnabled_SAG = FALSE;
        isPerFragmentChoosed_SAG = FALSE;
        singleTap_SAG = FALSE;
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
