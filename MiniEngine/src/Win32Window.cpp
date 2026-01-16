#include <glad/glad.h>
#include "Win32Window.h"
#include "../resource.h"
// #include <gl/GL.h>
#include <stdexcept>
// <stdexpect> can be used  to through runtime errors if something fails
// (not used yet, but useful for feature error handling)

/* 
    Window procedure (callback funtion)
    -----------------------------------
    This funtion receives and handles messages sent by windows
    to our windw (Keyboard, mouse, close button, resize, etc.)
*/
static Win32Window* gWindow = nullptr; // global pointer to access class

typedef HGLRC(WINAPI* PFNWGLCREATECONTEXTATTRIBSARBPROC)
(HDC, HGLRC, const int*);


static LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{

    switch(msg)
    {
        case WM_CLOSE:
            // Trigger applcation quit when user click the close (x) button
            PostQuitMessage(0);
            return 0;

        case WM_SIZE:
        {
            if (gWindow)
            {
                gWindow->framebufferWidth  = LOWORD(lParam);
                gWindow->framebufferHeight = HIWORD(lParam);

                if (gWindow->framebufferHeight == 0)
                    gWindow->framebufferHeight = 1;

                gWindow->resized = true;
            }
            return 0;
        }


        case WM_KEYDOWN:
            // ESC key → exit
            if (wParam == VK_ESCAPE)
            {
                PostQuitMessage(0);
                return 0;
            }

            // F or f → fullscreen toggle
            if (wParam == 'F')
            {
                if (gWindow)
                    gWindow->ToggleFullscreen();
                return 0;
            }
            break;

        case WM_DESTROY:
            // Window is being destroyed
            // No extra cleanup here because destructor handles it
            return 0;
    }

    // Default processing for all unhandled messages
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

/*
    Constructor
    -----------
    Creates a Win32 window and intializes OpenGL
*/
Win32Window::Win32Window(int w, int h, const wchar_t* title) : width(w), height(h) // Intialize window size using initializer list
{
    //
    gWindow = this;
    // Get handle to the current application insatnce
    hInstance = GetModuleHandleW(nullptr);

    /*
        Define window class
        -------------------
        WNDCLASS describes how the window beahves
    */

    WNDCLASSW wc{};
    wc.style = CS_OWNDC;
    // CS_OWNDC:
    // Each window gets its own Device Context (impotant for OpenGL)

    wc.lpfnWndProc = WindowProc;
    // Assign our cutom message handler

    wc.hInstance = hInstance;
    // Application insatnce handle

    wc.lpszClassName = L"MiniEngineWindow";
    // Unique name for this window class

    // Register the window class with windows
    RegisterClassW(&wc);

    /*
        Create the actual window
    */

    hwnd = CreateWindowExW(
        0,                              // Extended window style
        wc.lpszClassName,               // Window class name
        title,                          // Window Title (Caption)
        WS_OVERLAPPEDWINDOW | WS_VISIBLE,// Standard resizable window + visible immediately
        CW_USEDEFAULT, CW_USEDEFAULT,   // Use default Position
        width, height,                  // Window size
        nullptr,                        // Parent Winodw (none)
        nullptr,                        // Menu (none)
        hInstance,                      // Application instance
        nullptr                         // Extra craetion data
    );

    HICON hIcon = LoadIconW(
        hInstance,
        MAKEINTRESOURCEW(IDI_APP_ICON) 
    );


    // Big icon (taskbar, Alt+Tab)
    SendMessage(hwnd, WM_SETICON, ICON_BIG, (LPARAM)hIcon);

    // Small icon (title bar)
    SendMessage(hwnd, WM_SETICON, ICON_SMALL, (LPARAM)hIcon);


    // Get Device context (DC) for the window 
    // DC is required for OpenGL rendering
    hdc = GetDC(hwnd);

    // Intialize OpenGL context and settings
    InitOpenGL();
}

/*
    Initialize OpenGL (WGL) 
    -----------------------
    Sets Pixel format and creates OpenGL rendering context
*/

void Win32Window::InitOpenGL()
{
    /*
        Describe desired pixel format
        -----------------------------
        Tells Windows how the framebuffer shoul look
    */

    PIXELFORMATDESCRIPTOR pfd{};
    pfd.nSize = sizeof(pfd);
    pfd.nVersion = 1;

    pfd.dwFlags = 
        PFD_DRAW_TO_WINDOW  |           // Rendering directly to a window
        PFD_SUPPORT_OPENGL  |           // OpenGL support
        PFD_DOUBLEBUFFER;               // Enable double buffering

    pfd.iPixelType = PFD_TYPE_RGBA;
    // RGBA color Mode

    pfd.cColorBits = 32;
    // 32-bit color buffer (8 bits per channel)

    pfd.cDepthBits = 24;
    // 24-bit depth buffer (Z-buffer)

    pfd.cStencilBits = 8;
    // 8-bit stencil buffer (UseFull for advanced effects)

    // Ask Windows to choose the closest supprot pixel format
    int pixelFormat = ChoosePixelFormat(hdc, &pfd);

    // Apply the chosen pixel format to the device context
    SetPixelFormat(hdc, pixelFormat, &pfd);

    // Create OpenGL rendering conetxt
    // 1️⃣ Create temporary legacy OpenGL context
    HGLRC tempContext = wglCreateContext(hdc);
    wglMakeCurrent(hdc, tempContext);

    // 2️⃣ Load WGL + OpenGL function pointers
    if (!gladLoadGL())
        throw std::runtime_error("Failed to initialize GLAD");

    // 3️⃣ Get modern context creation function
    auto wglCreateContextAttribsARB =
        (PFNWGLCREATECONTEXTATTRIBSARBPROC)
        wglGetProcAddress("wglCreateContextAttribsARB");

    if (!wglCreateContextAttribsARB)
        throw std::runtime_error("wglCreateContextAttribsARB not supported");

    // 4️⃣ Create modern OpenGL 3.3 Core context
    int attribs[] =
    {
        0x2091, 3, // WGL_CONTEXT_MAJOR_VERSION_ARB
        0x2092, 3, // WGL_CONTEXT_MINOR_VERSION_ARB
        0x9126, 0x00000001, // WGL_CONTEXT_PROFILE_MASK_ARB (CORE)
        0
    };

    hglrc = wglCreateContextAttribsARB(hdc, 0, attribs);

    // 5️⃣ Switch to modern context
    wglMakeCurrent(nullptr, nullptr);
    wglDeleteContext(tempContext);
    wglMakeCurrent(hdc, hglrc);


}

/*
    Process Windows messages
    ------------------------
    Called every frame in the main loop
*/

bool Win32Window::ProcessMessages()
{
    MSG msg{};

    // Process all pending messages (non-bloking)
    while(PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE))
    {
        // WM_QUIT means application should exit
        if(msg.message == WM_QUIT)
        {
            return false;
        }

        // Convert virtual-key messages into character messages
        TranslateMessage(&msg);

        // Send message to wWindProc
        DispatchMessage(&msg);
    }

    // Application should continue running
    return true;
}

/* 
    SwapBuffers
    -----------
    Displays rendered frame on the screen
*/

void Win32Window::SwapBuffers()
{
    // Swap front and back buffer (double buffering)
    ::SwapBuffers(hdc);
}

/*
    Destructor
    ----------
    Cleans up openGL and Win32 resources
*/

Win32Window::~Win32Window()
{
    // Detach OpenGL context from device context
    wglMakeCurrent(nullptr, nullptr);

    // Delete OpenGL rendering conetext
    wglDeleteContext(hglrc);

    // Release device context
    ReleaseDC(hwnd, hdc);

    // Destroy the window
    DestroyWindow(hwnd);
}



void Win32Window::ToggleFullscreen()
{
    isFullscreen = !isFullscreen;

    if (isFullscreen)
    {
        GetWindowRect(hwnd, &windowRect);

        SetWindowLongPtr(hwnd, GWL_STYLE, WS_POPUP | WS_VISIBLE);

        HMONITOR hMonitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
        MONITORINFO mi{ sizeof(mi) };
        GetMonitorInfo(hMonitor, &mi);

        SetWindowPos(
            hwnd,
            HWND_TOP,
            mi.rcMonitor.left,
            mi.rcMonitor.top,
            mi.rcMonitor.right - mi.rcMonitor.left,
            mi.rcMonitor.bottom - mi.rcMonitor.top,
            SWP_FRAMECHANGED
        );

        ShowWindow(hwnd, SW_SHOW);
    }
    else
    {
        SetWindowLongPtr(hwnd, GWL_STYLE, WS_OVERLAPPEDWINDOW | WS_VISIBLE);

        SetWindowPos(
            hwnd,
            HWND_TOP,
            windowRect.left,
            windowRect.top,
            windowRect.right - windowRect.left,
            windowRect.bottom - windowRect.top,
            SWP_FRAMECHANGED
        );

        ShowWindow(hwnd, SW_SHOW);
    }
}
