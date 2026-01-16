function main() 
{
    // Get the canvas
    var canvas = document.getElementById('AMC');
    if (canvas == null) 
    {
        console.log('canvas element cannot be obtained\n');
        return;
    }
    else
    {
        console.log('canvas element obtained successfully\n');
    }
    // get the 2D context from the canvas
    var context = canvas.getContext('2d');
    if (context == null) 
    {
        console.log('2D context cannot be obtained\n');
        return;
    }
    else
    {
        console.log('2D context obtained successfully\n');
    }
    // tell the context to make the canvas background black
    context.fillStyle = '#000000ff'; // black color
    context.fillRect(0, 0, canvas.width, canvas.height);

    // to show the text ceteraly set contex atterbutes accordingly
    context.textAlign = 'center';
    // set horizontal alignment to center
    context.textBaseline = 'middle';
    // set the text font and size
    context.font = '48px sans-serif';
    context.fillStyle = '#4100e4ff'; 
    // set the text
    var str = 'Hello World!!!';
    // draw the text at center of canvas
    context.fillText(str, canvas.width / 2, canvas.height / 2);

    // register our callback function as event listeners
    window.onload = main;
    window.addEventListener('keydown', keyDown, false);
    window.addEventListener('mousedown', mouseDown, false);

}

function keyDown(event)
{
    // Code
    alert('Key is pressed');
    
    switch(event.key)
    {
        case 'Escape':
            window.close();
            break;
    }
}

function mouseDown(event)
{
    // Code
    alert('Mouse is clicked');
}
