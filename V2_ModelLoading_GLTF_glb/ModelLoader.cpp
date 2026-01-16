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

static void SlerpQuat(
    float* out,
    const float* a,
    const float* b,
    float t)
{
    float dot =
        a[0]*b[0] + a[1]*b[1] +
        a[2]*b[2] + a[3]*b[3];

        
    if (dot < 0.0f)
    {
        dot = -dot;
        for (int i = 0; i < 4; i++)
            out[i] = a[i] + t * (-b[i] - a[i]);
    }
    else
    {
        for (int i = 0; i < 4; i++)
            out[i] = a[i] + t * (b[i] - a[i]);
    }

    float len = sqrtf(
        out[0]*out[0] + out[1]*out[1] +
        out[2]*out[2] + out[3]*out[3]);

    for (int i = 0; i < 4; i++)
        out[i] /= len;
}


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
    for (auto& m : meshes)
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, m.textureID);

        glBindVertexArray(m.vao);
        glDrawElements(GL_TRIANGLES, m.indexCount, m.indexType, 0);
        glBindVertexArray(0);
    }
}


void ModelLoader::Update(float time)
{
    // Always keep a valid matrix
    animatedNodeMatrix = vmath::mat4::identity();

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
        if (duration <= 0.0f)
            continue;

        float t = fmod(time, duration);

        int i0 = 0, i1 = 0;
        for (int i = 0; i < inputAcc.count - 1; i++)
        {
            if (t >= times[i] && t <= times[i + 1])
            {
                i0 = i;
                i1 = i + 1;
                break;
            }
        }

        float denom = times[i1] - times[i0];
        float factor = 0.0f;

        if (denom > 1e-6f)
            factor = (t - times[i0]) / denom;

        tinygltf::Node& node =
            anim->model.nodes[channel.target_node];

        // ---------- TRANSLATION ----------
        if (channel.target_path == "translation")
        {
            node.translation = {
                (1 - factor) * values[i0*3+0] + factor * values[i1*3+0],
                (1 - factor) * values[i0*3+1] + factor * values[i1*3+1],
                (1 - factor) * values[i0*3+2] + factor * values[i1*3+2]
            };
        }
        // ---------- SCALE ----------
        else if (channel.target_path == "scale")
        {
            node.scale = {
                (1 - factor) * values[i0*3+0] + factor * values[i1*3+0],
                (1 - factor) * values[i0*3+1] + factor * values[i1*3+1],
                (1 - factor) * values[i0*3+2] + factor * values[i1*3+2]
            };
        }
        // ---------- ROTATION ----------
        else if (channel.target_path == "rotation")
        {
            float q0[4] = {
                values[i0*4+0],
                values[i0*4+1],
                values[i0*4+2],
                values[i0*4+3]
            };

            float q1[4] = {
                values[i1*4+0],
                values[i1*4+1],
                values[i1*4+2],
                values[i1*4+3]
            };

            float q[4];

            // Safe SLERP
            float dot =
                q0[0]*q1[0] + q0[1]*q1[1] +
                q0[2]*q1[2] + q0[3]*q1[3];

            if (dot < 0.0f)
            {
                for (int i = 0; i < 4; i++)
                    q1[i] = -q1[i];
            }

            for (int i = 0; i < 4; i++)
                q[i] = q0[i] + factor * (q1[i] - q0[i]);

            float len = sqrtf(
                q[0]*q[0] + q[1]*q[1] +
                q[2]*q[2] + q[3]*q[3]);

            if (len > 1e-6f)
            {
                for (int i = 0; i < 4; i++)
                    q[i] /= len;

                node.rotation = { q[0], q[1], q[2], q[3] };
            }
        }
    }

    // FINAL animated node matrix (safe)
    int nodeIndex =
        animation.channels[0].target_node;

    animatedNodeMatrix =
        GetNodeMatrix(anim->model.nodes[nodeIndex]);
}
