#pragma once

#include <vector>
#include <GL/glew.h>
#include "vmath.h"

// ================= Vertex =================
struct Vertex
{
    float pos[3];
    float normal[3];
    float uv[2];
};

// ================= Mesh =================
struct GLTFMesh
{
    GLuint vao = 0;
    GLuint vbo = 0;
    GLuint ebo = 0;

    GLuint textureID = 0;

    bool isTransparent = false;
    float alpha = 1.0f;          // 🔥 ADD THIS
    int alphaMode = 0;           // 0=OPAQUE, 1=MASK, 2=BLEND

    GLenum indexType;
    unsigned int indexCount;
};

// ================= Model Loader =================
class ModelLoader
{
public:
    bool Load(const char* path);
    void Update(float time);   // animation update
    void Draw();

private:
    std::vector<GLTFMesh> meshes;

    // opaque pointer (real type is hidden in cpp)
    void* animationState = nullptr;

public:
    vmath::mat4 animatedNodeMatrix = vmath::mat4::identity();

};
