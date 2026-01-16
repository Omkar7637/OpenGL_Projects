var canvas = null;
var gl = null;
var bFullScreen = false;

var canvas_original_width;
var canvas_original_height;

var requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame
                            || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame;

var uColorUniform;

// Webgl related Variables
const MyAttributes =
{
    AMC_ATTRIBUTE_POSITION:0,
};

var shaderProgramObject = null;
var mvpUniform;
var vao = null;
var vbo = null;
var prespectiveProjectionMatrix;

function main() 
{
    // Get the canvas
    canvas = document.getElementById('AMC');
    if (canvas == null) 
    {
        console.log('canvas element cannot be obtained\n');
        return;
    }
    else
    {
        console.log('canvas element obtained successfully\n');
    }


    canvas_original_width = canvas.width;
    canvas_original_height = canvas.height;

    window.addEventListener('keydown', keyDown, false);
    window.addEventListener('click', mouseDown, false);
    window.addEventListener("resize", resize, false);

    // intialize
    initialize();
    resize();
    display();

}


function keyDown(event)
{
    // Code

    switch(event.keyCode)
    {
        case 70: //F in ASCII
        case 102: //f in ASCII
            toggleFullScreen();
            break;
        case 27:
            uninitialize();
            window.close();
            break;
        
    }
}

function mouseDown(event)
{
    // Code
}


function toggleFullScreen() {

    var fullscreen_element =
    document.fullscreenElement ||
    document.mozFullScreenElement ||
    document.webkitFullscreenElement ||
    document.msFullscreenElement ||
    null;

    if(fullscreen_element == null)
    {
        if(canvas.requestFullscreen) canvas.requestFullscreen();
        else if(canvas.mozRequestFullScreen) canvas.mozRequestFullScreen();
        else if(canvas.webkitRequestFullscreen) canvas.webkitRequestFullscreen();
        else if(canvas.msRequestFullscreen) canvas.msRequestFullscreen();

        bFullScreen = true;
    }
    else
    {
        if(document.exitFullscreen) document.exitFullscreen();
        else if(document.mozCancelFullScreen) document.mozCancelFullScreen();
        else if(document.webkitExitFullscreen) document.webkitExitFullscreen();
        else if(document.msExitFullscreen) document.msExitFullscreen();


        bFullScreen = false;
    }
}


function initialize()
{
    // Code
    // get the 2D context from the canvas
    gl = canvas.getContext("webgl2");
    if (gl == null) 
    {
        console.log('webgl2 context cannot be obtained\n');
        return;
    }
    else
    {
        console.log('webgl2 context obtained successfully\n');
    }

    // Set viewport width/height
    gl.viewportWidth = canvas.width;
    gl.viewportHeight = canvas.height;

    
    // ================== Vertex Shader ==========================
    var vertexShaderObject = gl.createShader(gl.VERTEX_SHADER);
    var vertexShaderSourceCode =
    "#version 300 es\n" +
    "precision mediump float;\n" +
    "in vec4 aPosition;\n" +
    "uniform mat4 uMVPMatrix;\n" +
    "void main(void)\n" +
    "{\n" +
    "    gl_Position = uMVPMatrix * aPosition;\n" +
    "}\n";


    gl.shaderSource(vertexShaderObject, vertexShaderSourceCode);
    gl.compileShader(vertexShaderObject);

    if (gl.getShaderParameter(vertexShaderObject, gl.COMPILE_STATUS) == false) 
    {
        var error = gl.getShaderInfoLog(vertexShaderObject);
        if(error.length > 0)
        {
            alert(error);
            uninitialize();
        }else
        {
            console.log("Vertex shader succesfull");
        }
    }

    // Fragment Shader
    var fragmentShaderObject = gl.createShader(gl.FRAGMENT_SHADER);

    var fragmentShaderSourceCode =
    "#version 300 es\n" +
    "precision mediump float;\n" +
    "uniform vec3 uColor;\n" +     // NEW
    "out vec4 fragColor;\n" +
    "void main(void)\n" +
    "{\n" +
    "    fragColor = vec4(uColor, 1.0);\n" +
    "}\n";




    gl.shaderSource(fragmentShaderObject, fragmentShaderSourceCode);
    gl.compileShader(fragmentShaderObject);

    if (gl.getShaderParameter(fragmentShaderObject, gl.COMPILE_STATUS) == false) 
    {
        var error = gl.getShaderInfoLog(fragmentShaderObject);
        if(error.length > 0)
        {
            alert(error);
            uninitialize();
        } 
        else 
        {
            console.log("Fragment shader successful");
        }
    }

    shaderProgramObject = gl.createProgram();

    gl.attachShader(shaderProgramObject, vertexShaderObject);
    gl.attachShader(shaderProgramObject, fragmentShaderObject);

    // Attribute binding
    gl.bindAttribLocation(shaderProgramObject, MyAttributes.AMC_ATTRIBUTE_POSITION, "aPosition");

    // Link
    gl.linkProgram(shaderProgramObject);

    if(gl.getProgramParameter(shaderProgramObject, gl.LINK_STATUS) == false) 
    {
        var error = gl.getProgramInfoLog(shaderProgramObject);
        if(error.length > 0)
        {
            alert(error);
            uninitialize();
        } 
        else 
        {
            console.log("Shader Program linked successfully");
        }
    }
    else 
    {
        console.log("Shader Program linked successfully");
    }

    // get uniform location 
    uMVPMatrixUniform = gl.getUniformLocation(shaderProgramObject, "uMVPMatrix");
    uColorUniform = gl.getUniformLocation(shaderProgramObject, "uColor");   // NEW

    var rectangle_position = new Float32Array([
        -1.0, -1.0, 0.0,
        -1.0, 1.0, 0.0,
        1.0, 1.0, 0.0,
        1.0, -1.0, 0.0
    ]);


    vao = gl.createVertexArray();
    gl.bindVertexArray(vao);

    // Position VBO
    vbo = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(gl.ARRAY_BUFFER, rectangle_position, gl.STATIC_DRAW);
    gl.vertexAttribPointer(MyAttributes.AMC_ATTRIBUTE_POSITION, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(MyAttributes.AMC_ATTRIBUTE_POSITION);

    gl.bindBuffer(gl.ARRAY_BUFFER, null);
    gl.bindVertexArray(null);

    // enable depth
    gl.clearDepth(1.0);
    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);

    prespectiveProjectionMatrix = mat4.create();

    // Clear color
    gl.clearColor(0.0, 0.0, 1.0, 1.0);
}

function resize()
{
    // Code
    if(bFullScreen == true)
    {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }
    else
    {
        canvas.width = canvas_original_width;
        canvas.height = canvas_original_height;
    }
    gl.viewport(0, 0, canvas.width, canvas.height);

    // set prespective projection
    mat4.perspective(prespectiveProjectionMatrix, 45.0, parseFloat(canvas.width)/parseFloat(canvas.height), 0.1, 100.0);
}
function display()
{
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.useProgram(shaderProgramObject);


    // ModelView Matrix (Translate)
    var modelViewMatrix = mat4.create();
    mat4.translate(modelViewMatrix, modelViewMatrix, [0.0, 0.0, -4.0]);

    // Compute MVP
    var modelViewProjectionMatrix = mat4.create();
    mat4.multiply(modelViewProjectionMatrix, prespectiveProjectionMatrix, modelViewMatrix);

    gl.uniformMatrix4fv(uMVPMatrixUniform, false, modelViewProjectionMatrix);

    gl.bindVertexArray(vao);
    gl.drawArrays(gl.TRIANGLE_FAN, 0, 4);
    gl.bindVertexArray(null);

    gl.useProgram(null);

    requestAnimationFrame(display, canvas);
}



function update()
{
    // code
}

function uninitialize()
{

    // Exit fullscreen if needed
    if(bFullScreen)
    {
        toggleFullScreen();
    }

    if(vbo)
    {
        gl.deleteBuffer(vbo);
        vbo = null;
    }

    if(vao)
    {
        gl.deleteVertexArray(vao);
        vao = null;
    }

    


    if(shaderProgramObject)
    {
        gl.useProgram(shaderProgramObject);

        var shaderObjects = gl.getAttachedShaders(shaderProgramObject);

        for(let i = 0; i < shaderObjects.length; i++)
        {
            gl.detachShader(shaderProgramObject, shaderObjects[i]);
            gl.deleteShader(shaderObjects[i]);
            shaderObjects[i] = null;
        }

        gl.useProgram(null);
        gl.deleteProgram(shaderProgramObject);
        shaderProgramObject = null;
    }



}

