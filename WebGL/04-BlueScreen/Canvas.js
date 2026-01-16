var canvas = null;
var gl = null;
var bFullScreen = false;

var canvas_original_width;
var canvas_original_height;

var requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame
                            || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame;


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
}

function display()
{
    // Code
    gl.clear(gl.COLOR_BUFFER_BIT);

    // DOUBLE BUFFERING
    requestAnimationFrame(display, canvas);


}

function update()
{
    // code
}

function uninitialize()
{
    // Code
}