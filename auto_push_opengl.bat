@echo off

cd /d "C:\Users\OmkarKashid\Desktop\OpenGL_Projects"

git add .

git commit --allow-empty -m "Auto push %date% %time%"

git push origin main
