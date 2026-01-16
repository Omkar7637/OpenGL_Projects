#define TINYGLTF_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include "ModelLoader.h"
#include "tiny_gltf.h"
#include <cmath>
#include "vmath.h"
#include <iostream>

struct AnimationState
{
    tinygltf::Model model;
};



// ================= TEXTURE =================
static GLuint CreateTexture(const tinygltf::Image& image)
{
    GLuint tex;
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);

    // IMPORTANT for glTF
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    GLenum format = (image.component == 4) ? GL_RGBA : GL_RGB;

    glTexImage2D(
        GL_TEXTURE_2D,
        0,
        format,
        image.width,
        image.height,
        0,
        format,
        GL_UNSIGNED_BYTE,
        image.image.data()
    );

    glGenerateMipmap(GL_TEXTURE_2D);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glBindTexture(GL_TEXTURE_2D, 0);
    return tex;
}

// ================= LOAD =================
bool ModelLoader::Load(const char* path)
{
    tinygltf::Model model;
    tinygltf::TinyGLTF loader;
    std::string err, warn;

    bool ok = false;
    std::string p(path);

    if (p.find(".glb") != std::string::npos)
        ok = loader.LoadBinaryFromFile(&model, &err, &warn, path);
    else
        ok = loader.LoadASCIIFromFile(&model, &err, &warn, path);

    if (!warn.empty()) std::cout << warn << std::endl;
    if (!err.empty())  std::cout << err << std::endl;
    if (!ok) return false;

    // ================= LOAD IMAGES =================
    std::vector<GLuint> glTextures;
    for (const auto& img : model.images)
        glTextures.push_back(CreateTexture(img));

    // ================= LOAD MESHES =================
    for (const auto& mesh : model.meshes)
    {
        for (const auto& prim : mesh.primitives)
        {
            GLTFMesh m{};

            // -------- POSITIONS --------
            const auto& posAcc = model.accessors[prim.attributes.at("POSITION")];
            const auto& posView = model.bufferViews[posAcc.bufferView];
            const float* positions =
                reinterpret_cast<const float*>(
                    &model.buffers[posView.buffer].data[
                        posView.byteOffset + posAcc.byteOffset]);

            // -------- TEXCOORD --------
            const float* uvs = nullptr;
            if (prim.attributes.count("TEXCOORD_0"))
            {
                const auto& uvAcc = model.accessors[prim.attributes.at("TEXCOORD_0")];
                const auto& uvView = model.bufferViews[uvAcc.bufferView];
                uvs = reinterpret_cast<const float*>(
                    &model.buffers[uvView.buffer].data[
                        uvView.byteOffset + uvAcc.byteOffset]);
            }

            std::vector<Vertex> vertices(posAcc.count);
            for (size_t i = 0; i < posAcc.count; i++)
            {
                vertices[i].pos[0] = positions[i * 3 + 0];
                vertices[i].pos[1] = positions[i * 3 + 1];
                vertices[i].pos[2] = positions[i * 3 + 2];

                if (uvs)
                {
                    vertices[i].uv[0] = uvs[i * 2 + 0];
                    vertices[i].uv[1] = uvs[i * 2 + 1];
                }
            }

            // -------- INDICES (CRITICAL FIX) --------
            const auto& idxAcc = model.accessors[prim.indices];
            const auto& idxView = model.bufferViews[idxAcc.bufferView];
            const void* idxData =
                &model.buffers[idxView.buffer].data[
                    idxView.byteOffset + idxAcc.byteOffset];

            if (idxAcc.componentType == TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT)
                m.indexType = GL_UNSIGNED_SHORT;
            else
                m.indexType = GL_UNSIGNED_INT;

            m.indexCount = static_cast<unsigned int>(idxAcc.count);

            // -------- TEXTURE --------
            m.textureID = 0;
            if (prim.material >= 0)
            {
                const auto& mat = model.materials[prim.material];
                if (mat.pbrMetallicRoughness.baseColorTexture.index >= 0)
                {
                    int texIndex = mat.pbrMetallicRoughness.baseColorTexture.index;
                    int imgIndex = model.textures[texIndex].source;
                    m.textureID = glTextures[imgIndex];
                }
            }

            
            // -------- OPENGL BUFFERS --------
            glGenVertexArrays(1, &m.vao);
            glBindVertexArray(m.vao);

            glGenBuffers(1, &m.vbo);
            glBindBuffer(GL_ARRAY_BUFFER, m.vbo);
            glBufferData(GL_ARRAY_BUFFER,
                         vertices.size() * sizeof(Vertex),
                         vertices.data(),
                         GL_STATIC_DRAW);

            glGenBuffers(1, &m.ebo);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m.ebo);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                         idxAcc.count *
                         (m.indexType == GL_UNSIGNED_SHORT ? sizeof(unsigned short) : sizeof(unsigned int)),
                         idxData,
                         GL_STATIC_DRAW);

            // POSITION -> location 0
            glEnableVertexAttribArray(0);
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE,
                                  sizeof(Vertex), (void*)0);

            // TEXCOORD -> location 2
            glEnableVertexAttribArray(2);
            glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE,
                                  sizeof(Vertex), (void*)(sizeof(float) * 3));

            glBindVertexArray(0);

            meshes.push_back(m);
        }
    }

    AnimationState* anim = new AnimationState();
    anim->model = model;
    animationState = anim;

    return true;
}

static vmath::mat4 GetNodeMatrix(const tinygltf::Node& node)
{
    // ---------------- Translation ----------------
    vmath::mat4 T = vmath::translate(
        node.translation.size() > 0 ? (float)node.translation[0] : 0.0f,
        node.translation.size() > 1 ? (float)node.translation[1] : 0.0f,
        node.translation.size() > 2 ? (float)node.translation[2] : 0.0f
    );

    // ---------------- Scale ----------------
    vmath::mat4 S = vmath::scale(
        node.scale.size() > 0 ? (float)node.scale[0] : 1.0f,
        node.scale.size() > 1 ? (float)node.scale[1] : 1.0f,
        node.scale.size() > 2 ? (float)node.scale[2] : 1.0f
    );

    // ---------------- Rotation (Quaternion → Matrix) ----------------
    vmath::mat4 R = vmath::mat4::identity();

    if (node.rotation.size() == 4)
    {
        float x = (float)node.rotation[0];
        float y = (float)node.rotation[1];
        float z = (float)node.rotation[2];
        float w = (float)node.rotation[3];

        float xx = x * x;
        float yy = y * y;
        float zz = z * z;
        float xy = x * y;
        float xz = x * z;
        float yz = y * z;
        float wx = w * x;
        float wy = w * y;
        float wz = w * z;

        // COLUMN 0
        R[0][0] = 1.0f - 2.0f * (yy + zz);
        R[0][1] = 2.0f * (xy + wz);
        R[0][2] = 2.0f * (xz - wy);
        R[0][3] = 0.0f;

        // COLUMN 1
        R[1][0] = 2.0f * (xy - wz);
        R[1][1] = 1.0f - 2.0f * (xx + zz);
        R[1][2] = 2.0f * (yz + wx);
        R[1][3] = 0.0f;

        // COLUMN 2
        R[2][0] = 2.0f * (xz + wy);
        R[2][1] = 2.0f * (yz - wx);
        R[2][2] = 1.0f - 2.0f * (xx + yy);
        R[2][3] = 0.0f;

        // COLUMN 3
        R[3][0] = 0.0f;
        R[3][1] = 0.0f;
        R[3][2] = 0.0f;
        R[3][3] = 1.0f;
    }

    return T * R * S;
}



// ================= DRAW =================
void ModelLoader::Draw()
{

    AnimationState* anim =
        static_cast<AnimationState*>(animationState);

    vmath::mat4 nodeMatrix = vmath::mat4::identity();

    if (anim && !anim->model.nodes.empty())
    {
        nodeMatrix = GetNodeMatrix(anim->model.nodes[0]);
    }


    for (auto& m : meshes)
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, m.textureID);

        AnimationState* anim =
        static_cast<AnimationState*>(animationState);

        vmath::mat4 nodeMatrix = vmath::mat4::identity();

        // ⚠️ USE THE NODE THAT OWNS THE MESH
        // For now we assume mesh is attached to node 0
        // (This is true for your cube GLB)
        if (anim && !anim->model.nodes.empty())
        {
            nodeMatrix = GetNodeMatrix(anim->model.nodes[0]);
        }


        glBindVertexArray(m.vao);
        glDrawElements(GL_TRIANGLES,
                       m.indexCount,
                       m.indexType,
                       0);

        glBindVertexArray(0);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

void ModelLoader::Update(float time)
{
    if (!animationState)
        return;

    AnimationState* anim =
        static_cast<AnimationState*>(animationState);

    if (anim->model.animations.empty())
        return;

    const tinygltf::Animation& animation =
        anim->model.animations[0];

    for (const auto& channel : animation.channels)
    {
        const tinygltf::AnimationSampler& sampler =
            animation.samplers[channel.sampler];

        const tinygltf::Accessor& inputAcc =
            anim->model.accessors[sampler.input];
        const tinygltf::Accessor& outputAcc =
            anim->model.accessors[sampler.output];

        const tinygltf::BufferView& inView =
            anim->model.bufferViews[inputAcc.bufferView];
        const tinygltf::BufferView& outView =
            anim->model.bufferViews[outputAcc.bufferView];

        const float* times =
            reinterpret_cast<const float*>(
                &anim->model.buffers[inView.buffer].data[
                    inView.byteOffset + inputAcc.byteOffset]);

        const float* values =
            reinterpret_cast<const float*>(
                &anim->model.buffers[outView.buffer].data[
                    outView.byteOffset + outputAcc.byteOffset]);

        float duration = times[inputAcc.count - 1];
        float t = fmod(time, duration);

        int index = 0;
        while (index < inputAcc.count - 1 && t > times[index + 1])
            index++;

        tinygltf::Node& node =
            anim->model.nodes[channel.target_node];

        if (channel.target_path == "translation")
        {
            node.translation = {
                values[index * 3 + 0],
                values[index * 3 + 1],
                values[index * 3 + 2]
            };
        }
        else if (channel.target_path == "rotation")
        {
            node.rotation = {
                values[index * 4 + 0],
                values[index * 4 + 1],
                values[index * 4 + 2],
                values[index * 4 + 3]
            };
        }
        else if (channel.target_path == "scale")
        {
            node.scale = {
                values[index * 3 + 0],
                values[index * 3 + 1],
                values[index * 3 + 2]
            };
        }
    }

    if (!anim->model.nodes.empty() &&
    !anim->model.nodes[0].rotation.empty())
    {
        printf("rot.w = %f\n", anim->model.nodes[0].rotation[3]);
    }

}


