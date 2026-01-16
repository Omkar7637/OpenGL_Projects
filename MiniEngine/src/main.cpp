#include "Win32Window.h"
// Includes our custom Win32 + OpenGL window abstraction

// #include <gl/GL.h>
// Include legacy OpenGL header provided by windows
// Contains declarations for function like glClearColor, glClear, etc

#pragma comment(lib, "opengl32.lib")
// Tells MSVC linker to link against opengl32.lib automatically
// required to use OpenGL functions on windows

#include "Shader.h"
#include "glad/glad.h"

float vertices[] =
{
     0.0f,  0.5f, 0.0f,
    -0.5f, -0.5f, 0.0f,
     0.5f, -0.5f, 0.0f
};

const char* vertexShaderSrc = R"(
#version 330 core
layout (location = 0) in vec3 aPos;
void main()
{
    gl_Position = vec4(aPos, 1.0);
}
)";

const char* fragmentShaderSrc = R"(
#version 330 core
out vec4 FragColor;
void main()
{
    FragColor = vec4(0.9, 0.4, 0.2, 1.0);
}
)";

int main()
{
    /*
        Create window instance
        ----------------------
        - 1280x720 resolution
        - Title shown on window title bar
        - internally:
            - Creates win32 window
            - Initializes OpenGL context (WGL)
    */
   Win32Window window(1280, 720, L"MiniEngine - Win32 + OpenGL");

    glViewport(0, 0, 1280, 720);

    unsigned int VAO, VBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);

    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    Shader shader(vertexShaderSrc, fragmentShaderSrc);

    if (window.resized)
    {
        glViewport(
            0,
            0,
            window.framebufferWidth,
            window.framebufferHeight
        );

        window.resized = false;
    }



   /*
        Main Application Loop
        ---------------------
        Runs until ProcessMessages() returns false
        (WM_QUIT is received)
   */

   while(true)
   {

    // If Window is closed -> Exit Loop
    if(!window.ProcessMessages())
    {
        break;
    }
    /*
        Set Clear Color
        ---------------
        Defines the color used when clearing the color buffer
        RGBA format:
        - R = 0.1 (dark blue tone)
        - G = 0.1
        - B = 0.2
        - A = 1.0 (fully opaque)
    */

    glClearColor(0.1f, 0.1f, 0.15f, 1.0f);

    /*
        Clear the frame buffer
        ----------------------
        GL_COLOR_BUFFER_BIT clears the color buffer
        (screen is filled with clear color)
    */

    glClear(GL_COLOR_BUFFER_BIT);


    shader.Use();
    glBindVertexArray(VAO);
    glDrawArrays(GL_TRIANGLES, 0, 3);

    /*
        Presents the required frame
        ---------------------------
        Swap back buffer with front buffer
        Makes the cleared frame visible on screen
    */

    window.SwapBuffers();
   }

   // Program exits cleanly after winodw is closed
   return 0;
}