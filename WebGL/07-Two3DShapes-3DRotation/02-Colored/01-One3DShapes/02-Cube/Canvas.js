var canvas = null;
var gl = null;
var bFullscreen = false;
var canvas_original_width;
var canvas_original_height;

// WebGL related variables
const vertexAttributeEnum =
{
    AMC_ATTRIBUTE_POSITION: 0,
    AMC_ATTRIBUTE_COLOR:1
};

var shaderProgramObject = null;

var vao = null;
var vbo_position = null;
var vbo_color = null;

var angle_cube_X = 0.0;
var angle_cube_Y = 0.0;
var angle_cube_Z = 0.0;


var mvpMatrixUniform;

var perspectiveProjectionMatrix;

var requestAnimationFrame =
    window.requestAnimationFrame ||         // google
    window.webkitRequestAnimationFrame ||   // safari
    window.mozRequestAnimationFrame ||      // mozilla
    window.oRequestAnimationFrame ||        // operra
    window.msRequestAnimationFrame;         // edge


// Our main function
function main()
{
    // Get Canvas aplya engine kdun magnar jo tayar kely HTML mdhe jo engine aplyala milvun denar ahe js file mdhe 
    canvas = document.getElementById("SAG");
    if(canvas == null)
        console.log("Getting Canvas Failed !!!\n");
    else
        console.log("Getting Canvas Succeeded !!!\n");

    // set canvas width and height for future use
    canvas_original_width = canvas.width;
    canvas_original_height = canvas.height;

     // Set Canvas background color to black
    //context.fillStyle = "black";    

    // Paint the canvas with above color
    //context.fillRect(0, 0, canvas.width, canvas.height);

    // Draw Text
    //drawText("Hello World !!!");

    // Register for keyboard events
    window.addEventListener("keydown", keyDown, false); 

    // Register for mouse events
    window.addEventListener("click", mouseDown, false);

    window.addEventListener("resize", resize, false);

    initialize();

    resize();

    display();


}

function keyDown(event)
{
    // Code
    switch(event.keyCode)
    {
        case 81:    // Q
        case 113:   // q
            uninitialize();
            window.close();
            break;

        case 70:
        case 102:
            toggleFullscreen();
            //drawText("Hello World !!!");
            break;
    }
}

function mouseDown()
{
   
}
function toggleFullscreen()
{
    var fullscreen_element = 
        document.fullscreenElement || 
        document.webkitFullscreenElement ||
        document.mozFullScreenElement ||
        document.msFullscreenElement ||
        null;

    // If not fullscreen
    if(fullscreen_element == null)
    {
        if(canvas.requestFullScreen)
        {
            canvas.requestFullScreen();
        }
        else if(canvas.webkitRequestFullscreen)
        {
            canvas.webkitRequestFullscreen();
        }
        else if(canvas.mozRequestFullScreen)
        {
            canvas.mozRequestFullScreen();
        }
        else if(canvas.msRequestFullScreen)
        {
            canvas.msRequestFullScreen();
        }
        bFullscreen = true;
    }
    else    // if already fullscreen
    {
        if(document.exitFullScreen)
        {
            document.exitFullScreen();
        }
        else if(document.webkitExitFullscreen)
        {
            document.webkitExitFullscreen();
        }
        else if(document.mozCancelFullScreen)
        {
            document.mozCancelFullScreen();
        }
        else if(document.msExitFullScreen)
        {
            document.msExitFullScreen();
        }
        bFullscreen = false;
    }
}

function initialize() {
    // Code
    // Get Context from above canvas
    gl = canvas.getContext("webgl2");
    if (gl == null)
        console.log("Getting WebGL2-Context failed!!!\n");
    else
        console.log("Getting WebGL2-Context succeeded !!!\n");

    // Set WebGL2 context's view width & view height properties
    gl.viewportWidth = canvas.width;
    gl.viewportHeight = canvas.height;

    // Vertex Shader
    var vertexShaderSourceCode =
        (
            "#version 300 es" +
            "\n" +
            "in vec4 aPosition;" +
            "in vec4 aColor;" +
            "uniform mat4 uMVPMatrix;" +
            "out vec4 oColor;" +
            "void main(void)" +
            "{" +
            "gl_Position=uMVPMatrix*aPosition;" +
            "oColor=aColor;" +
            "}"
        );

    var vertexShaderObject = gl.createShader(gl.VERTEX_SHADER);

    gl.shaderSource(vertexShaderObject, vertexShaderSourceCode);

    gl.compileShader(vertexShaderObject);

    if (gl.getShaderParameter(vertexShaderObject, gl.COMPILE_STATUS) == false) {
        var error = gl.getShaderInfoLog(vertexShaderObject);
        if (error.length > 0) {
            var log = "Vertex Shader Compilation Error : " + error;
            alert(log);
            uninitialize();
        }
    }
    else {
        console.log("Vertex Shader Compiled Successfully !!!\n");
    }

    // Fragment shader
    var fragmentShaderSourceCode =
        (
            "#version 300 es" +
            "\n" +
            "precision highp float;" +
            "in vec4 oColor;" +
            "out vec4 FragColor;" +
            "void main(void)" +
            "{" +
            "FragColor=oColor;" +
            "}"
        );

    var fragmentShaderObject = gl.createShader(gl.FRAGMENT_SHADER);

    gl.shaderSource(fragmentShaderObject, fragmentShaderSourceCode);

    gl.compileShader(fragmentShaderObject);

    if (gl.getShaderParameter(fragmentShaderObject, gl.COMPILE_STATUS) == false) {
        var error = gl.getShaderInfoLog(fragmentShaderObject);
        if (error.length > 0) {
            var log = "Fragment Shader Compilation Error  : " + error;
            alert(log);
            uninitialize();
        }
    }
    else {
        console.log("Fragment Shader Compiled Successfully !!!\n");
    }

    // Shader Program
    shaderProgramObject = gl.createProgram();

    gl.attachShader(shaderProgramObject, vertexShaderObject);
    gl.attachShader(shaderProgramObject, fragmentShaderObject);

    // pre-linking binding
    gl.bindAttribLocation(shaderProgramObject, vertexAttributeEnum.AMC_ATTRIBUTE_POSITION, "aPosition");
    gl.bindAttribLocation(shaderProgramObject, vertexAttributeEnum.AMC_ATTRIBUTE_COLOR, "aColor");

    // Linking
    gl.linkProgram(shaderProgramObject);

    if (gl.getProgramParameter(shaderProgramObject, gl.LINK_STATUS) == false) {
        var error = gl.getProgramInfoLog(shaderProgramObject);
        if (error.length > 0) {
            var log = "Shader Program Linking Error : " + error;
            alert(log);
            uninitialize();
        }
    }
    else {
        console.log("Shader Program Linked Successfully !!!\n");
    }

    mvpMatrixUniform = gl.getUniformLocation(shaderProgramObject, "uMVPMatrix");

    // Geomatry attribute array declaration

    var cube_position = new Float32Array([
        // top
        1.0, 1.0, -1.0,
        -1.0, 1.0, -1.0,
        -1.0, 1.0, 1.0,
        1.0, 1.0, 1.0,

        // bottom
        1.0, -1.0, -1.0,
        -1.0, -1.0, -1.0,
        -1.0, -1.0, 1.0,
        1.0, -1.0, 1.0,

        // front
        1.0, 1.0, 1.0,
        -1.0, 1.0, 1.0,
        -1.0, -1.0, 1.0,
        1.0, -1.0, 1.0,

        // back
        1.0, 1.0, -1.0,
        -1.0, 1.0, -1.0,
        -1.0, -1.0, -1.0,
        1.0, -1.0, -1.0,

        // right
        1.0, 1.0, -1.0,
        1.0, 1.0, 1.0,
        1.0, -1.0, 1.0,
        1.0, -1.0, -1.0,

        // left
        -1.0, 1.0, 1.0,
        -1.0, 1.0, -1.0,
        -1.0, -1.0, -1.0,
        -1.0, -1.0, 1.0,
    ]);

    var cube_color = new Float32Array([
        0.0, 1.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 1.0, 0.0,

        1.0, 0.5, 0.0,
        1.0, 0.5, 0.0,
        1.0, 0.5, 0.0,
        1.0, 0.5, 0.0,

        1.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        1.0, 0.0, 0.0,

        1.0, 1.0, 0.0,
        1.0, 1.0, 0.0,
        1.0, 1.0, 0.0,
        1.0, 1.0, 0.0,

        0.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 1.0,

        1.0, 0.0, 1.0,
        1.0, 0.0, 1.0,
        1.0, 0.0, 1.0,
        1.0, 0.0, 1.0
    ]);

    // For Triangle

    // Vao
    vao= gl.createVertexArray();
    gl.bindVertexArray(vao);

    // VBO for position
    vbo_position = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo_position);
    gl.bufferData(gl.ARRAY_BUFFER, cube_position, gl.STATIC_DRAW);
    gl.vertexAttribPointer(vertexAttributeEnum.AMC_ATTRIBUTE_POSITION, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vertexAttributeEnum.AMC_ATTRIBUTE_POSITION);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);

    //gl.bindVertexArray(null);

    // VBO for Color
    vbo_color = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo_color);
    gl.bufferData(gl.ARRAY_BUFFER, cube_color, gl.STATIC_DRAW);
    gl.vertexAttribPointer(vertexAttributeEnum.AMC_ATTRIBUTE_COLOR, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vertexAttributeEnum.AMC_ATTRIBUTE_COLOR);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);

    gl.bindVertexArray(null);


    // Depth Initialization
    gl.clearDepth(1.0);
    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);


    // Set clear color
    // 1st WebGL API
    gl.clearColor(0.0, 0.0, 0.0, 1.0);

    // initialize projection matrix
    // first time we are using func of min.js
    perspectiveProjectionMatrix = mat4.create();

}

function resize()
{
    // Code
    if (canvas.height <= 0) {
        canvas.height = 1;
    }
    if (bFullscreen == true) {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }
    else {
        canvas.width = canvas_original_width;
        canvas.height = canvas_original_height;
    }

    // Set viewport
    gl.viewport(0, 0, canvas.width, canvas.height);

    // Set Perspective Projection
    mat4.perspective(perspectiveProjectionMatrix, 45.0, parseFloat(canvas.width) / parseFloat(canvas.height), 0.1, 100.0)
}

function display()
{
    // Code
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.useProgram(shaderProgramObject);

    // Transformations
    var modelViewMatrix = mat4.create();
    var modelViewProjectionMatrix = mat4.create();

    var translateMatrix = mat4.create();
    var rotationMatrix = mat4.create();

    var rotationMatrix_X = mat4.create();
    var rotationMatrix_Y = mat4.create();
    var rotationMatrix_Z = mat4.create();

    mat4.identity(modelViewMatrix);
    mat4.identity(modelViewProjectionMatrix);

    mat4.identity(translateMatrix);
    mat4.identity(rotationMatrix);

    mat4.identity(rotationMatrix_X);
    mat4.identity(rotationMatrix_Y);
    mat4.identity(rotationMatrix_Z);

    mat4.translate(translateMatrix, translateMatrix, [0.0, 0.0, -6.0]);

    mat4.rotate(rotationMatrix_X, rotationMatrix_X, angle_cube_X, [1.0, 0.0, 0.0]);
    mat4.rotate(rotationMatrix_Y, rotationMatrix_Y, angle_cube_Y, [0.0, 1.0, 0.0]);
    mat4.rotate(rotationMatrix_Z, rotationMatrix_Z, angle_cube_Z, [0.0, 0.0, 1.0]);

    mat4.multiply(rotationMatrix, rotationMatrix_X, rotationMatrix_Y);
    mat4.multiply(rotationMatrix, rotationMatrix, rotationMatrix_Z);


    //mat4.translate(modelViewMatrix, modelViewMatrix, [-1.5, 0.0, -4.0]);
    mat4.multiply(modelViewMatrix, translateMatrix, rotationMatrix);
    mat4.multiply(modelViewProjectionMatrix, perspectiveProjectionMatrix, modelViewMatrix);

    gl.uniformMatrix4fv(mvpMatrixUniform, false, modelViewProjectionMatrix);

    gl.bindVertexArray(vao);

    gl.drawArrays(gl.TRIANGLE_FAN, 0, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 4, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 8, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 12, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 16, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 20, 4);

    gl.bindVertexArray(null);

    gl.useProgram(null);

    update();

    // do Dubble buffering
    requestAnimationFrame(display, canvas);
}

function update()
{
    //Code
    angle_cube_X = angle_cube_X - 0.002;
    angle_cube_Y = angle_cube_Y - 0.003;
    angle_cube_Z = angle_cube_Z - 0.004;

    if (angle_cube_X <= 0.0)
    {
        angle_cube_X = angle_cube_X + 360.0;
    }
    if (angle_cube_Y <= 0.0)
    {
        angle_cube_Y = angle_cube_Y + 360.0;
    }
    if (angle_cube_Z <= 0.0)
    {
        angle_cube_Z = angle_cube_Z + 360.0;
    }
}

function uninitialize()
{
    // Code
    
    if (shaderProgramObject)    // this stmt can be if(shaderProgramObject != null)
    {
        gl.useProgram(shaderProgramObject);
        var shaderObjects = gl.getAttachedShaders(shaderProgramObject);
        if (shaderObjects && shaderObjects.length > 0) {
            for (let i = 0; i < shaderObjects.length; i++) {
                gl.detachShader(shaderProgramObject, shaderObjects[i]);
                gl.deleteShader(shaderObjects[i]);
                shaderObjects[i] = null;
            }
        }
        gl.useProgram(null);
        gl.deleteProgram(shaderProgramObject);
        shaderProgramObject = null;
    }


    if (vbo_color) {
        gl.deleteBuffer(vbo_color);
        vbo_color = null;
    }
    if (vbo_position) {
        gl.deleteBuffer(vbo_position);
        vbo_position = null;
    }
    
    if (vao) {
        gl.deleteVertexArray(vao);
        vao = null;
    }
   // window.close();
}



