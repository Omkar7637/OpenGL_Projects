#include "OGL_Common.h"

void releaseOpenGLRendering(void)
{
	if(ghrc == NULL && ghdc == NULL)
		return;

	if(wglGetCurrentContext() == ghrc)
		wglMakeCurrent(NULL, NULL);

	if(ghrc)
	{
		wglDeleteContext(ghrc);
		ghrc = NULL;
	}

	if(ghdc)
	{
		ReleaseDC(ghwnd, ghdc);
		ghdc = NULL;
	}
}

void uninitialized(void)
{
	if(IsWindow(ghwnd) && gbFullScreen == TRUE)
	{
		togglefullscreen();
		gbFullScreen = FALSE;
	}

	OGL_ModelShutdown();

	if(ghrc != NULL || ghdc != NULL)
		releaseOpenGLRendering();

	if(IsWindow(ghwnd))
		DestroyWindow(ghwnd);

	if(gpFile)
	{
		fprintf(gpFile, "Program terminated sucessfully");
		fclose(gpFile);
		gpFile = NULL;
	}
}
