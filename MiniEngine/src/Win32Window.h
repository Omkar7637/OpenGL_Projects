#pragma once
// Ensures this header file is included only once during compilation
// Prevents multiple defination errors

#include <Windows.h>
// Includes Win32 API definations:
// - HWND   : Window handle
// - HDC    : Device context (used for drawing)
// - HGLRC  : OpenGL rendering context
// - HINSTANCE : Apllication instance handle

// This class encapsulates a Win32 window with an OpenGL context
class Win32Window
{
    public:
        // Constructor
        // Creates a window with guven width, height, and title
        // Also responsible for intializing Win32 + OpenGL internally
        Win32Window(int width, int height, const wchar_t* title);

        // Destructor 
        // Cleans up OpenGL context, device conext, and dextroys the window
        ~Win32Window();

        // Processes Windows messages (Keyboard, mouse, close, etc.)
        // Typically callled once per frame in the main loop
        // Returns false when WM_WUIT is recived (Apllication should exit)
        bool ProcessMessages();

        // Swaps the front and back buffers
        // Required for double-buffered OpenGL rendering
        // Shows the Rendered frame on screen
        void SwapBuffers();

        // FullScreen
        void ToggleFullscreen();

    private:
        // Intializes OpenGL-specific things:
        // - Chose pixel format
        // - Creates OpenGL rendering Context (HGLRC)
        // - Make the Context current
        void InitOpenGL();


    public:
        // Handle to the current application instance
        // Provoided by Windows when the program starts
        HINSTANCE hInstance;

        // Handle to the Win32 window
        // Used for message handling and window operations
        HWND hwnd;

        // Handle to the device context
        // Interface between windows and OpenGL for rendering
        HDC hdc;

        // Handle ro the OpenGL rendering context
        // Stores all OpenGL state  for this window
        HGLRC hglrc;

        // Width of the window in pixels
        int width;

        // Height of the window in pixels
        int height;

        // FullScreen Related 
        bool isFullscreen = false;
        RECT windowRect;

        int framebufferWidth  = 0;
        int framebufferHeight = 0;
        bool resized = false;

};