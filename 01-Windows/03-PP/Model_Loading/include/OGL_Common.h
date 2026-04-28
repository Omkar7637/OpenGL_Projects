#pragma once

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <gl/glew.h>
#include <gl/GL.h>

#include "math_bridge.h"

#pragma comment(lib, "glew32.lib")
#pragma comment(lib, "opengl32.lib")

#define WIN_WIDTH 800
#define WIN_HEIGHT 600

extern BOOL gbFullScreen;
extern HWND ghwnd;
extern DWORD dwStyle;
extern WINDOWPLACEMENT wpPrev;

extern char gszLogFileName[];
extern FILE *gpFile;

extern BOOL gbActiveWindow;
extern BOOL gbEscKeyIsPressed;

extern HDC ghdc;
extern HGLRC ghrc;

extern float presepectiveProjectionMatrix[16];

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
void togglefullscreen(void);

int initialized(void);
void printGLInfo(void);
void resize(int width, int height);
void display(void);
void update(void);

int OGL_ModelInit(void);
void OGL_ModelDraw(void);
void OGL_ModelShutdown(void);

void releaseOpenGLRendering(void);
void uninitialized(void);
