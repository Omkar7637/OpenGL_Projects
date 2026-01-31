#!/bin/sh

#  Build.sh
#  
 

rm -rf OGL.app OGL.o Log.txt
mkdir -p OGL.app/Contents/MacOS
clang++ -c Sphere.mm
clang++ -Wno-deprecated-declarations -c -o OGL.o OGL.mm
clang++ -o OGL.app/Contents/MacOS/OGL OGL.o Sphere.o -framework Cocoa -framework QuartzCore -framework OpenGL
