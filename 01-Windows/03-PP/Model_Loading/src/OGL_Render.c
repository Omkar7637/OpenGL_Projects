#include "OGL_Common.h"

void display(void)
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	OGL_ModelDraw();
	SwapBuffers(ghdc);
}

void update(void)
{
}
