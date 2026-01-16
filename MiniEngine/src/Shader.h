#pragma once
#include <string>

class Shader
{
public:
    unsigned int ID;
    Shader(const char* vertexSrc, const char* fragmentSrc);
    void Use();
};
