var canvas = null;
var gl = null;
var bFullscreen = false;
var canvas_original_width;
var canvas_original_height;

// WebGL related variables
const vertexAttributeEnum =
{
    AMC_ATTRIBUTE_POSITION:0,
    AMC_ATTRIBUTE_TEXCOORDS:1
};

var shaderProgramObject = null;

var vao_pyramid = null;
var vbo_position_pyramid = null;
var vbo_texture_pyramid = null;

var vao_cube = null;
var vbo_position_cube = null;
var vbo_texture_cube = null;

var mvpMatrixUniform;

var perspectiveProjectionMatrix;

var kundali_texture;
var stone_texture;

var angle_cube_X = 0.0;
var angle_cube_Y = 0.0;
var angle_cube_Z = 0.0;

var angle_pyramid = 0.0;

var textureSamplerUniform;

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
    canvas = document.getElementById("AMC");
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
    var fullScreen_Element =
        document.fullscreenElement ||
        document.webkitFullscreenElement ||
        document.mozFullScreenElement ||
        document.msFullscreenElement ||
        null;

    if (fullScreen_Element == null) {
        if (canvas.requestFullScreen)
            canvas.requestFullScreen();
        else if (canvas.webkitRequestFullscreen)
            canvas.webkitRequestFullscreen();
        else if (canvas.mozRequestFullScreen)
            canvas.mozRequestFullScreen();
        else if (canvas.msRequestFullScreen)
            canvas.msRequestFullScreen();
        bFullscreen = true;
    }
    else {
        if (document.exitFullScreen)
            document.exitFullScreen();
        else if (document.webkitExitFullscreen)
            document.webkitExitFullscreen();
        else if (document.mozCancelFullScreen)
            document.mozCancelFullScreen();
        else if (document.msExitFullScreen)
            document.msExitFullScreen();
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
            "in vec2 aTexCoord;" +
            "uniform mat4 uMVPMatrix;" +
            "out vec2 oTexCoord;" +
            "void main(void)" +
            "{" +
            "gl_Position= uMVPMatrix*aPosition;" +
            "oTexCoord=aTexCoord;" +
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
            "precision highp float;"+
            "in vec2 oTexCoord;" +
            "out vec4 FragColor;" +
            "uniform highp sampler2D uTextureSampler;" +
            "void main(void)" +
            "{" +
            "FragColor=texture(uTextureSampler, oTexCoord);" +
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
    gl.bindAttribLocation(shaderProgramObject, vertexAttributeEnum.AMC_ATTRIBUTE_TEXCOORDS, "aTexCoord");

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
    textureSamplerUniform = gl.getUniformLocation(shaderProgramObject, "uTextureSampler");


    // Geomatry attribute array declaration

    // Geomatry attribute array declaration
    var pyramid_position = new Float32Array([
        // front
        0.0, 1.0, 0.0,
        -1.0, -1.0, 1.0,
        1.0, -1.0, 1.0,

        // right
        0.0, 1.0, 0.0,
        1.0, -1.0, 1.0,
        1.0, -1.0, -1.0,

        // back
        0.0, 1.0, 0.0,
        1.0, -1.0, -1.0,
        -1.0, -1.0, -1.0,

        // left
        0.0, 1.0, 0.0,
        -1.0, -1.0, -1.0,
        -1.0, -1.0, 1.0
    ]);

    var pyramid_texcoords = new Float32Array([
        //1.0, 1.0,
        //0.0, 1.0,
        //1.0, 0.0,
        //0.0, 0.0,
        //1.0, 0.0
        //0.0, 1.0
        // front
        0.5, 1.0, // front-top
        0.0, 0.0, // front-left
        1.0, 0.0, // front-right

        // right
        0.5, 1.0, // right-top
        1.0, 0.0, // right-left
        0.0, 0.0, // right-right

        // back
        0.5, 1.0, // back-top
        0.0, 0.0, // back-left
        1.0, 0.0, // back-right

        // left
        0.5, 1.0, // left-top
        1.0, 0.0, // left-left
        0.0, 0.0, // left-right
    ]);

    var cube_position = new Float32Array([
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

    var cube_texcoords = new Float32Array([
        // front
        1.0, 1.0, // top-right of front
        0.0, 1.0, // top-left of front
        0.0, 0.0, // bottom-left of front
        1.0, 0.0, // bottom-right of front

        // right
        1.0, 1.0, // top-right of right
        0.0, 1.0, // top-left of right
        0.0, 0.0, // bottom-left of right
        1.0, 0.0, // bottom-right of right

        // back
        1.0, 1.0, // top-right of back
        0.0, 1.0, // top-left of back
        0.0, 0.0, // bottom-left of back
        1.0, 0.0, // bottom-right of back

        // left
        1.0, 1.0, // top-right of left
        0.0, 1.0, // top-left of left
        0.0, 0.0, // bottom-left of left
        1.0, 0.0, // bottom-right of left

        // top
        1.0, 1.0, // top-right of top
        0.0, 1.0, // top-left of top
        0.0, 0.0, // bottom-left of top
        1.0, 0.0, // bottom-right of top

        // bottom
        1.0, 1.0, // top-right of bottom
        0.0, 1.0, // top-left of bottom
        0.0, 0.0, // bottom-left of bottom
        1.0, 0.0, // bottom-right of bottom
    ])

    // Vao
    vao_pyramid = gl.createVertexArray();
    gl.bindVertexArray(vao_pyramid);

    // VBO
    vbo_position_pyramid = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo_position_pyramid);
    gl.bufferData(gl.ARRAY_BUFFER, pyramid_position, gl.STATIC_DRAW);
    gl.vertexAttribPointer(vertexAttributeEnum.AMC_ATTRIBUTE_POSITION, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vertexAttributeEnum.AMC_ATTRIBUTE_POSITION);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);


    vbo_texture_pyramid = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo_texture_pyramid);
    gl.bufferData(gl.ARRAY_BUFFER, pyramid_texcoords, gl.STATIC_DRAW);
    gl.vertexAttribPointer(vertexAttributeEnum.AMC_ATTRIBUTE_TEXCOORDS, 2, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vertexAttributeEnum.AMC_ATTRIBUTE_TEXCOORDS);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);

    gl.bindVertexArray(null);

    // Vao
    vao_cube = gl.createVertexArray();
    gl.bindVertexArray(vao_cube);

    // VBO
    vbo_position_cube = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo_position_cube);
    gl.bufferData(gl.ARRAY_BUFFER, cube_position, gl.STATIC_DRAW);
    gl.vertexAttribPointer(vertexAttributeEnum.AMC_ATTRIBUTE_POSITION, 3, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vertexAttributeEnum.AMC_ATTRIBUTE_POSITION);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);


    vbo_texture_cube = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo_texture_cube);
    gl.bufferData(gl.ARRAY_BUFFER, cube_texcoords, gl.STATIC_DRAW);
    gl.vertexAttribPointer(vertexAttributeEnum.AMC_ATTRIBUTE_TEXCOORDS, 2, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(vertexAttributeEnum.AMC_ATTRIBUTE_TEXCOORDS);
    gl.bindBuffer(gl.ARRAY_BUFFER, null);

    gl.bindVertexArray(null);

    kundali_texture = loadGLTexture("kundali.png");		// kundali, stone
    stone_texture = loadGLTexture("stone.png");

    // Depth Initialization
    gl.clearDepth(1.0);
    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);

    //gl.enable(gl.TEXTURE_2D);

    // Set clear color
    // 1st WebGL API
    gl.clearColor(0.0, 0.0, 0.0, 1.0);

    // initialize projection matrix
    // first time we are using func of min.js
    perspectiveProjectionMatrix = mat4.create();

}

function loadGLTexture(imageFileName) {
    var texture;
    texture = gl.createTexture();
    texture.image = new Image();
    texture.image.src = imageFileName;
    texture.image.onload = function () {
        gl.bindTexture(
            gl.TEXTURE_2D,
            texture
        );
        gl.pixelStorei(
            gl.UNPACK_ALIGNMENT,
            4
        );
        gl.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_MAG_FILTER,
            gl.NEAREST
        );
        gl.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_MIN_FILTER,
            gl.NEAREST
        );
        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            texture.image
        );
        gl.generateMipmap(
            gl.TEXTURE_2D
        )
        gl.bindTexture(
            gl.TEXTURE_2D,
            null
        );
    }

    return texture;
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

    var angle = 0.0;

    // Transformations
    var modelViewMatrix = mat4.create();
    var modelViewProjectionMatrix = mat4.create();

    var translateMatrix = mat4.create();
    var rotationMatrix = mat4.create();

    mat4.identity(modelViewMatrix);
    mat4.identity(modelViewProjectionMatrix);

    mat4.identity(translateMatrix);
    mat4.identity(rotationMatrix);

    mat4.translate(translateMatrix, translateMatrix, [1.7, 0.0, -6.0]);

    angle = degToRad(angle_cube_X);
    mat4.rotateX(rotationMatrix, rotationMatrix, angle);

    angle = degToRad(angle_cube_Y);
    mat4.rotateY(rotationMatrix, rotationMatrix, angle);

    angle = degToRad(angle_cube_Z);
    mat4.rotateZ(rotationMatrix, rotationMatrix, angle);

    mat4.multiply(modelViewMatrix, translateMatrix, rotationMatrix);

    mat4.scale(modelViewMatrix, modelViewMatrix, [0.75, 0.75, 0.75]);
   
    mat4.multiply(modelViewProjectionMatrix, perspectiveProjectionMatrix, modelViewMatrix);

    gl.uniformMatrix4fv(mvpMatrixUniform, false, modelViewProjectionMatrix);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, kundali_texture);
    gl.uniform1i(textureSamplerUniform, 0);

    gl.bindVertexArray(vao_cube);

    gl.drawArrays(gl.TRIANGLE_FAN, 0, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 4, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 8, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 12, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 16, 4);
    gl.drawArrays(gl.TRIANGLE_FAN, 20, 4);

    gl.bindTexture(gl.TEXTURE_2D, null);
    gl.bindVertexArray(null);


    // __________________________________________________________

    mat4.identity(modelViewMatrix);
    mat4.identity(modelViewProjectionMatrix);

    mat4.identity(translateMatrix);
    mat4.identity(rotationMatrix);

    mat4.translate(translateMatrix, translateMatrix, [-1.7, 0.0, -6.0]);

    mat4.rotate(rotationMatrix, rotationMatrix, angle_pyramid, [0.0, 1.0, 0.0]);

    mat4.multiply(modelViewMatrix, translateMatrix, rotationMatrix);

    mat4.multiply(modelViewProjectionMatrix, perspectiveProjectionMatrix, modelViewMatrix);
    gl.uniformMatrix4fv(mvpMatrixUniform, false, modelViewProjectionMatrix);

    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, stone_texture);
    gl.uniform1i(textureSamplerUniform, 0);

    gl.bindVertexArray(vao_pyramid);
    gl.drawArrays(gl.TRIANGLES, 0, 12);
    gl.bindTexture(gl.TEXTURE_2D, null);
    gl.bindVertexArray(null);

    gl.useProgram(null);

    update();

    // do Dubble buffering
    requestAnimationFrame(display, canvas);
}

function degToRad(degrees) {
    return (degrees * Math.PI / 180.0);
}
function update()
{
    //Code
    angle_cube_X = angle_cube_X - 0.04;
    angle_cube_Y = angle_cube_Y - 0.06;
    angle_cube_Z = angle_cube_Z - 0.08;

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

    angle_pyramid = angle_pyramid + 0.003;
    if (angle_pyramid >= 360.0) {
        angle_pyramid = angle_pyramid - 360.0;
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

    if (kundali_texture) {
        gl.deleteTexture(1, kundali_texture);
        kundali_texture = null;
    }

    if (vbo_texture_cube) {
        gl.deleteBuffer(vbo_texture_cube);
        vbo_texture_cube = null;
    }
    if (vbo_position_cube) {
        gl.deleteBuffer(vbo_position_cube);
        vbo_position_cube = null;
    }
    if (vao_cube) {
        gl.deleteVertexArray(vao_cube);
        vao_cube = null;
    }
    if (stone_texture) {
        gl.deleteTexture(1, stone_texture);
        stone_texture = null;
    }

    if (vbo_texture_pyramid) {
        gl.deleteBuffer(vbo_texture_pyramid);
        vbo_texture_pyramid = null;
    }
    if (vbo_position_pyramid) {
        gl.deleteBuffer(vbo_position_pyramid);
        vbo_position_pyramid = null;
    }
    if (vao_pyramid) {
        gl.deleteVertexArray(vao_pyramid);
        vao_pyramid = null;
    }
   // window.close();
}



