//
//  MyView.m
//  OpenGLES
//
//  Created by apple on 09/11/24.
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
    AMC_ATTRIBUTE_COLOR
};

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
    mat4 perspectiveProjectionMatrix_AMC; // mat4 is in vmath.h

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

    // Variable To Handle Switch Between Shapes
    BOOL currentShapeGraph_AMC;
    BOOL currentShapeCircle_AMC;
    BOOL currentShapeSquare_AMC;
    BOOL currentShapeTriangle_AMC;
    
    int singleTap_AMC;
    BOOL doubleTab_AMC;
}

-(id)initWithFrame:(CGRect)frame
{
    // Code
    self = [super initWithFrame:frame];
    if (self)
    {
        // Variable Initialization
        currentShapeGraph_AMC = FALSE;
        currentShapeCircle_AMC = FALSE;
        currentShapeSquare_AMC = FALSE;
        currentShapeTriangle_AMC = FALSE;
        
        singleTap_AMC = 0;
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
        "#version 300 core                          "\
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
        "#version 300 core                          "\
        "\n                                         "\
        "precision highp float;                     "\
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
    mvpMatrixUniform_AMC = glGetUniformLocation(shaderProgramObject_AMC, "uMVPMatrix");

    [self initialize_graph];
    [self initialize_circle];
    [self initialize_square];
    [self initialize_triangle];
    
    // Step - 2 : For Depth Enable
    glClearDepthf(1.0f);        // Compulsory
    glEnable(GL_DEPTH_TEST);    // Compulsory
    glDepthFunc(GL_LEQUAL);     // Compulsory

    // Set The Clear Color Of Window
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

    // initialize ortho mat
    perspectiveProjectionMatrix_AMC = vmath::mat4::identity();

    [self resize:WIN_WIDTH :WIN_HEIGHT];
    
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
    
    [self uninitialize_graph];
    [self uninitialize_circle];
    [self uninitialize_square];
    [self uninitialize_triangle];
    
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
    singleTap_AMC++;
    if (singleTap_AMC == 1)
    {
        currentShapeCircle_AMC = TRUE;
    }
    
    if (singleTap_AMC == 2)
    {
        currentShapeSquare_AMC = TRUE;
    }
    
    if (singleTap_AMC == 3)
    {
        currentShapeTriangle_AMC = TRUE;
    }
    if (singleTap_AMC == 4)
    {
        currentShapeCircle_AMC = FALSE;
    }
    
    if (singleTap_AMC == 5)
    {
        currentShapeSquare_AMC = FALSE;
    }
    
    if (singleTap_AMC == 6)
    {
        currentShapeTriangle_AMC = FALSE;
        singleTap_AMC = 0;
    }
}

-(void)onDoubleTap:(UITapGestureRecognizer*)gestureRecognizer
{
    // Code
    
    if (doubleTab_AMC == FALSE)
    {
        currentShapeGraph_AMC = TRUE;
        doubleTab_AMC = TRUE;
    }
    else
    {
        currentShapeGraph_AMC = FALSE;
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
