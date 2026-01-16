#include "Shader.h"
#include <glad/glad.h>

Shader::Shader(const char* vSrc, const char* fSrc)
{
    unsigned int vs = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vs, 1, &vSrc, nullptr);
    glCompileShader(vs);

    unsigned int fs = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fs, 1, &fSrc, nullptr);
    glCompileShader(fs);

    ID = glCreateProgram();
    glAttachShader(ID, vs);
    glAttachShader(ID, fs);
    glLinkProgram(ID);

    glDeleteShader(vs);
    glDeleteShader(fs);
}

void Shader::Use()
{
    glUseProgram(ID);
}
