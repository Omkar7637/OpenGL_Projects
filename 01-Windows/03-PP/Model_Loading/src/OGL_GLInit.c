#include "OGL_Common.h"

int initialized(void)
{
	PIXELFORMATDESCRIPTOR pfd;
	int iPixelFormatIndex = 0;
	GLenum glewResult;

	ZeroMemory((void *)&pfd, sizeof(PIXELFORMATDESCRIPTOR));
	pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
	pfd.nVersion = 1;
	pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
	pfd.iPixelType = PFD_TYPE_RGBA;
	pfd.cColorBits = 32;
	pfd.cRedBits = 8;
	pfd.cGreenBits = 8;
	pfd.cBlueBits = 8;
	pfd.cAlphaBits = 8;
	pfd.cDepthBits = 32;

	ghdc = GetDC(ghwnd);
	if(ghdc == NULL)
	{
		fprintf(gpFile, "GetDC Function failed\n");
		return -1;
	}

	iPixelFormatIndex = ChoosePixelFormat(ghdc, &pfd);
	if(iPixelFormatIndex == 0)
	{
		fprintf(gpFile, "choose pixel format failed\n");
		return -2;
	}

	if(SetPixelFormat(ghdc, iPixelFormatIndex, &pfd) == FALSE)
	{
		fprintf(gpFile, "setPixel format failed");
		return -3;
	}

	ghrc = wglCreateContext(ghdc);
	if(ghrc == NULL)
	{
		fprintf(gpFile, "wgl context failed\n");
		return -4;
	}

	if(wglMakeCurrent(ghdc, ghrc) == FALSE)
	{
		fprintf(gpFile, "wglmake failed\n");
		return -5;
	}

	glewResult = glewInit();
	if(glewResult != GLEW_OK)
	{
		fprintf(gpFile, "glewInit Failed\n");
		return -6;
	}

	printGLInfo();

	if(OGL_ModelInit() != 0)
		return -7;

	glClearDepth(1.0f);
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	glClearColor(0.05f, 0.05f, 0.08f, 1.0f);

	math_mat4_identity(presepectiveProjectionMatrix);
	resize(WIN_WIDTH, WIN_HEIGHT);

	return 0;
}

void printGLInfo(void)
{
	GLint numExtensions;

	fprintf(gpFile, "OPENGL INFORMATION\n");
	fprintf(gpFile, "---------x--------\n");
	fprintf(gpFile, "openGL vendor : %s\n", glGetString(GL_VENDOR));
	fprintf(gpFile, "OpenGL Renderer : %s\n", glGetString(GL_RENDERER));
	fprintf(gpFile, "openGL version : %s\n", glGetString(GL_VERSION));
	fprintf(gpFile, "GLSL Version = %s\n", glGetString(GL_SHADING_LANGUAGE_VERSION));
	glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);
	fprintf(gpFile, "Extention Countes : %d\n", numExtensions);
	fprintf(gpFile, "---------x--------\n");
}

void resize(int width, int height)
{
	GLfloat aspect;

	if(height <= 0)
		height = 1;

	glViewport(0, 0, (GLsizei)width, (GLsizei)height);
	aspect = (GLfloat)width / (GLfloat)height;
	math_mat4_perspective(presepectiveProjectionMatrix, 45.0f, aspect, 0.1f, 100.0f);
}
