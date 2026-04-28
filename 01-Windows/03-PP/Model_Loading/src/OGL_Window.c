#include "OGL_Common.h"

LRESULT CALLBACK WndProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
	switch(iMsg)
	{
	case WM_CREATE:
		ZeroMemory((void *)&wpPrev, sizeof(WINDOWPLACEMENT));
		wpPrev.length = sizeof(WINDOWPLACEMENT);
		break;

	case WM_SETFOCUS:
		gbActiveWindow = TRUE;
		break;

	case WM_KILLFOCUS:
		gbActiveWindow = FALSE;
		break;

	case WM_ERASEBKGND:
		return 0;

	case WM_SIZE:
		resize((int)LOWORD(lParam), (int)HIWORD(lParam));
		break;

	case WM_KEYDOWN:
		switch(wParam)
		{
		case VK_ESCAPE:
			gbEscKeyIsPressed = TRUE;
			break;
		default:
			break;
		}
		break;

	case WM_CHAR:
		switch(wParam)
		{
		case 'F':
		case 'f':
			if(gbFullScreen == FALSE)
			{
				togglefullscreen();
				gbFullScreen = TRUE;
			}
			else
			{
				togglefullscreen();
				gbFullScreen = FALSE;
			}
			break;
		default:
			break;
		}
		break;

	case WM_DESTROY:
		ghwnd = NULL;
		PostQuitMessage(0);
		break;

	case WM_CLOSE:
		if(gbFullScreen == TRUE)
		{
			togglefullscreen();
			gbFullScreen = FALSE;
		}
		OGL_ModelShutdown();
		releaseOpenGLRendering();
		DestroyWindow(hwnd);
		return 0;

	default:
		break;
	}

	return DefWindowProc(hwnd, iMsg, wParam, lParam);
}

void togglefullscreen(void)
{
	MONITORINFO mi;

	if(gbFullScreen == FALSE)
	{
		dwStyle = GetWindowLong(ghwnd, GWL_STYLE);
		if(dwStyle & WS_OVERLAPPEDWINDOW)
		{
			ZeroMemory((void *)&mi, sizeof(MONITORINFO));
			mi.cbSize = sizeof(MONITORINFO);
			if(GetWindowPlacement(ghwnd, &wpPrev) && GetMonitorInfo(MonitorFromWindow(ghwnd, MONITORINFOF_PRIMARY), &mi))
			{
				SetWindowLong(ghwnd, GWL_STYLE, dwStyle & ~WS_OVERLAPPEDWINDOW);
				SetWindowPos(ghwnd, HWND_TOP, mi.rcMonitor.left, mi.rcMonitor.top,
					mi.rcMonitor.right - mi.rcMonitor.left, mi.rcMonitor.bottom - mi.rcMonitor.top,
					SWP_NOZORDER | SWP_FRAMECHANGED);
			}
		}
		ShowCursor(FALSE);
	}
	else
	{
		SetWindowPlacement(ghwnd, &wpPrev);
		SetWindowLong(ghwnd, GWL_STYLE, dwStyle | WS_OVERLAPPEDWINDOW);
		SetWindowPos(ghwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOOWNERZORDER | SWP_NOZORDER | SWP_FRAMECHANGED);
		ShowCursor(TRUE);
	}
}
