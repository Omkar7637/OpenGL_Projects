#include "OGL_Common.h"

BOOL gbFullScreen = FALSE;
HWND ghwnd = NULL;
DWORD dwStyle;
WINDOWPLACEMENT wpPrev;

char gszLogFileName[] = "Log.txt";
FILE *gpFile = NULL;

BOOL gbActiveWindow = FALSE;
BOOL gbEscKeyIsPressed = FALSE;

HDC ghdc = NULL;
HGLRC ghrc = NULL;

float presepectiveProjectionMatrix[16];
