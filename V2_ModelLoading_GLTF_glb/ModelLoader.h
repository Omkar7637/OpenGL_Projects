#pragma once

#include <vector>
#include <GL/glew.h>
#include "vmath.h"

// ================= Vertex =================
struct Vertex
{
    float pos[3];
    float uv[2];
};

// ================= Mesh =================
struct GLTFMesh
{
    GLuint vao;
    GLuint vbo;
    GLuint ebo;
    GLuint textureID;

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
