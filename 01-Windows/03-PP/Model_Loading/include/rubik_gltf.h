#ifndef RUBIK_GLTF_H
#define RUBIK_GLTF_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct RubikSubmesh
{
	unsigned int first_index;
	unsigned int index_count;
	unsigned int texture_index;
} RubikSubmesh;

typedef struct RubikCpuMesh
{
	float *positions;
	float *normals;
	float *tangents;
	float *uvs;
	unsigned int *indices;
	unsigned int vertex_count;
	unsigned int index_count;
	RubikSubmesh *submeshes;
	unsigned int submesh_count;
	float model_matrix[16];

	unsigned char **texture_rgba_list;
	int *texture_width_list;
	int *texture_height_list;
	unsigned int texture_count;

	unsigned char *texture_rgba;
	int texture_width;
	int texture_height;
	int loaded;
} RubikCpuMesh;

/*
 * Loads glTF 2.0 (.gltf or .glb) via cgltf: merges all triangle primitives in the default scene
 * (node transforms baked into vertices). Resolves buffer and image URIs relative to the glTF file.
 * Put the .gltf, .bin, and texture files in one folder and pass the full path to the main asset file.
 * Draco-compressed meshes are not supported. First base-color texture found is used (or 1x1 white).
 * Returns 0 on success, non-zero on failure (errbuf optional message).
 */
int rubik_load_from_gltf_path(const char *scene_gltf_path, RubikCpuMesh *out, char *errbuf, size_t errbuf_size);

void rubik_free_cpu_mesh(RubikCpuMesh *m);

#ifdef __cplusplus
}
#endif

#endif
