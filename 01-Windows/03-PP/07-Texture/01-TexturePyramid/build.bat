cl.exe /c /EHsc /I C:\glew-2.3.0\include OGL.cpp &&  rc.exe OGL.rc

link.exe OGL.obj OGL.res ^
/SUBSYSTEM:WINDOWS ^
/LIBPATH:C:\glew-2.3.0\lib\Release\x64 ^
glew32.lib opengl32.lib user32.lib gdi32.lib kernel32.lib
