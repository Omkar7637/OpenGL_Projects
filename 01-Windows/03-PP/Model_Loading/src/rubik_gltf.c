/*
 * glTF 2.0 mesh loader (cgltf + stb_image).
 * Pass path to a .gltf or .glb; buffers and images resolve next to that file (same folder).
 */

#include "rubik_gltf.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CGLTF_IMPLEMENTATION
#include "cgltf.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

static void dirname_inplace(char *path)
{
	size_t n = strlen(path);
	while(n > 0)
	{
		char ch = path[n - 1];
		if(ch == '\\' || ch == '/')
		{
			path[n - 1] = '\0';
			return;
		}
		n--;
	}
}

static int join_dir_uri(char *out, size_t cap, const char *gltf_path, const char *uri)
{
	char dir[768];
	size_t ld, lu;
	const char *u = uri;

	if(!gltf_path || !uri)
		return -1;
	strncpy(dir, gltf_path, sizeof(dir) - 1);
	dir[sizeof(dir) - 1] = '\0';
	dirname_inplace(dir);
	ld = strlen(dir);
	lu = strlen(u);
	if(ld + 1u + lu + 1u > cap)
		return -1;
	memcpy(out, dir, ld);
	out[ld] = '\\';
	memcpy(out + ld + 1u, u, lu + 1u);
	return 0;
}

static const char *uri_last_segment(const char *uri)
{
	const char *slash = strrchr(uri, '/');
	const char *bs = strrchr(uri, '\\');
	const char *p = uri;

	if(slash && (!bs || slash > bs))
		p = slash + 1;
	else if(bs)
		p = bs + 1;
	return p;
}

/*
 * If cgltf_load_buffers fails (e.g. scene.bin next to .gltf missing), try the same paths many
 * exporters use: parent of the .gltf folder (project root), then cwd with filename only.
 */
static cgltf_result try_read_external_buffer(cgltf_buffer *buf, const char *uri, const char *gltf_path)
{
	char path[1024];
	char dir[768];
	FILE *fp;
	long fsz;
	void *mem;
	const char *base;
	int n;

	if(!uri || strncmp(uri, "data:", 5) == 0 || strstr(uri, "://") != NULL)
		return cgltf_result_unknown_format;

	strncpy(dir, gltf_path, sizeof(dir) - 1);
	dir[sizeof(dir) - 1] = '\0';
	dirname_inplace(dir);

	/* 1: <folder of gltf>\<uri> (same as cgltf) */
	if(join_dir_uri(path, sizeof(path), gltf_path, uri) == 0)
	{
		fp = fopen(path, "rb");
		if(fp)
			goto read_ok;
	}

	/* 2: parent of that folder + uri — e.g. assets\..\scene.bin */
	n = snprintf(path, sizeof(path), "%s\\..\\%s", dir, uri);
	if(n > 0 && (size_t)n < sizeof(path))
	{
		fp = fopen(path, "rb");
		if(fp)
			goto read_ok;
	}

	/* 3: one more level up */
	n = snprintf(path, sizeof(path), "%s\\..\\..\\%s", dir, uri);
	if(n > 0 && (size_t)n < sizeof(path))
	{
		fp = fopen(path, "rb");
		if(fp)
			goto read_ok;
	}

	/* 4: cwd: filename only */
	base = uri_last_segment(uri);
	fp = fopen(base, "rb");
	if(fp)
		goto read_ok;

	return cgltf_result_file_not_found;

read_ok:
	fseek(fp, 0, SEEK_END);
	fsz = ftell(fp);
	if(fsz < 0)
	{
		fclose(fp);
		return cgltf_result_io_error;
	}
	fseek(fp, 0, SEEK_SET);
	if((cgltf_size)fsz != buf->size)
	{
		fclose(fp);
		return cgltf_result_data_too_short;
	}
	mem = malloc((size_t)buf->size);
	if(!mem)
	{
		fclose(fp);
		return cgltf_result_out_of_memory;
	}
	if(fread(mem, 1, (size_t)buf->size, fp) != (size_t)buf->size)
	{
		free(mem);
		fclose(fp);
		return cgltf_result_io_error;
	}
	fclose(fp);
	buf->data = mem;
	buf->data_free_method = cgltf_data_free_method_memory_free;
	return cgltf_result_success;
}

static cgltf_result load_buffers_fallback(cgltf_data *data, const char *gltf_path)
{
	cgltf_size i;
	cgltf_result r;

	for(i = 0; i < data->buffers_count; i++)
	{
		if(data->buffers[i].data)
			continue;
		if(!data->buffers[i].uri)
			continue;
		r = try_read_external_buffer(&data->buffers[i], data->buffers[i].uri, gltf_path);
		if(r != cgltf_result_success)
			return r;
	}
	return cgltf_result_success;
}

static void mat4_identity(float *m)
{
	memset(m, 0, sizeof(float) * 16);
	m[0] = m[5] = m[10] = m[15] = 1.0f;
}

static void mat4_mul_vec3(const float *m, const float *v, float *o)
{
	float w = m[3] * v[0] + m[7] * v[1] + m[11] * v[2] + m[15];
	if(fabsf(w) < 1e-20f)
		w = 1.0f;
	o[0] = (m[0] * v[0] + m[4] * v[1] + m[8] * v[2] + m[12]) / w;
	o[1] = (m[1] * v[0] + m[5] * v[1] + m[9] * v[2] + m[13]) / w;
	o[2] = (m[2] * v[0] + m[6] * v[1] + m[10] * v[2] + m[14]) / w;
}

/*
 * n' = inverse(G)^T * n, G = upper 3x3 column-major from m.
 */
static void mat3_inv_transpose_apply_normal(const float *m, const float *n, float *o)
{
	float a00 = m[0], a01 = m[4], a02 = m[8];
	float a10 = m[1], a11 = m[5], a12 = m[9];
	float a20 = m[2], a21 = m[6], a22 = m[10];
	float det = a00 * (a11 * a22 - a12 * a21) - a10 * (a01 * a22 - a02 * a21) + a20 * (a01 * a12 - a02 * a11);
	float invdet;
	float i00, i01, i02, i10, i11, i12, i20, i21, i22;
	float t0, t1, t2;
	float len;

	if(fabsf(det) < 1e-24f)
	{
		o[0] = n[0];
		o[1] = n[1];
		o[2] = n[2];
		return;
	}
	invdet = 1.0f / det;
	i00 = (a11 * a22 - a12 * a21) * invdet;
	i01 = (a02 * a21 - a01 * a22) * invdet;
	i02 = (a01 * a12 - a02 * a11) * invdet;
	i10 = (a12 * a20 - a10 * a22) * invdet;
	i11 = (a00 * a22 - a02 * a20) * invdet;
	i12 = (a02 * a10 - a00 * a12) * invdet;
	i20 = (a10 * a21 - a11 * a20) * invdet;
	i21 = (a01 * a20 - a00 * a21) * invdet;
	i22 = (a00 * a11 - a01 * a10) * invdet;
	/* (inverse)^T * n */
	t0 = i00 * n[0] + i10 * n[1] + i20 * n[2];
	t1 = i01 * n[0] + i11 * n[1] + i21 * n[2];
	t2 = i02 * n[0] + i12 * n[1] + i22 * n[2];
	len = sqrtf(t0 * t0 + t1 * t1 + t2 * t2);
	if(len > 1e-20f)
	{
		o[0] = t0 / len;
		o[1] = t1 / len;
		o[2] = t2 / len;
	}
	else
	{
		o[0] = 0.0f;
		o[1] = 1.0f;
		o[2] = 0.0f;
	}
}

static unsigned char *make_white_pixel(void)
{
	unsigned char *p = (unsigned char *)malloc(4u);
	if(p)
	{
		p[0] = p[1] = p[2] = p[3] = 255;
	}
	return p;
}

static size_t base64_decoded_byte_count(const char *b64)
{
	size_t len = strlen(b64);
	while(len > 0 && (b64[len - 1] == '\n' || b64[len - 1] == '\r'))
		len--;
	if(len == 0)
		return 0;
	{
		size_t n = (len / 4u) * 3u;
		if(b64[len - 1] == '=')
		{
			n--;
			if(len >= 2 && b64[len - 2] == '=')
				n--;
		}
		return n;
	}
}

static unsigned char *load_image_rgba(cgltf_data *data, cgltf_image *img, const char *gltf_path, int *w, int *h)
{
	unsigned char *rgba = NULL;
	char pathbuf[1024];
	char uribuf[768];
	const char *comma;
	int comp = 0;
	cgltf_options opt = {0};
	void *raw = NULL;
	size_t dec_len;

	(void)data;

	/* Keep native glTF texture orientation; forced global flip causes wrong mapping on many assets. */
	stbi_set_flip_vertically_on_load(0);

	if(!img)
		return NULL;

	if(img->buffer_view)
	{
		const uint8_t *ptr = cgltf_buffer_view_data(img->buffer_view);
		cgltf_size sz = img->buffer_view->size;
		if(ptr && sz > 0u)
			rgba = stbi_load_from_memory(ptr, (int)sz, w, h, &comp, 4);
		return rgba;
	}

	if(!img->uri)
		return NULL;

	if(strncmp(img->uri, "data:", 5) == 0)
	{
		comma = strchr(img->uri, ',');
		if(comma && (size_t)(comma - img->uri) >= 7u && strncmp(comma - 7, ";base64", 7) == 0)
		{
			dec_len = base64_decoded_byte_count(comma + 1);
			if(dec_len > 0u &&
			   cgltf_load_buffer_base64(&opt, (cgltf_size)dec_len, comma + 1, &raw) == cgltf_result_success && raw)
			{
				comp = 0;
				rgba = stbi_load_from_memory((const unsigned char *)raw, (int)dec_len, w, h, &comp, 4);
				free(raw);
			}
		}
		return rgba;
	}

	strncpy(uribuf, img->uri, sizeof(uribuf) - 1);
	uribuf[sizeof(uribuf) - 1] = '\0';
	cgltf_decode_uri(uribuf);
	if(join_dir_uri(pathbuf, sizeof(pathbuf), gltf_path, uribuf) != 0)
		return NULL;
	comp = 0;
	rgba = stbi_load(pathbuf, w, h, &comp, 4);
	if(!rgba)
	{
		char dir[768];
		int n;

		strncpy(dir, gltf_path, sizeof(dir) - 1);
		dir[sizeof(dir) - 1] = '\0';
		dirname_inplace(dir);
		n = snprintf(pathbuf, sizeof(pathbuf), "%s\\..\\%s", dir, uribuf);
		if(n > 0 && (size_t)n < sizeof(pathbuf))
		{
			comp = 0;
			rgba = stbi_load(pathbuf, w, h, &comp, 4);
		}
	}
	if(!rgba)
	{
		comp = 0;
		rgba = stbi_load(uri_last_segment(uribuf), w, h, &comp, 4);
	}
	return rgba;
}

static cgltf_image *pick_base_color_image(cgltf_material *mat)
{
	if(!mat)
		return NULL;
	if(mat->has_pbr_metallic_roughness && mat->pbr_metallic_roughness.base_color_texture.texture)
	{
		cgltf_texture *t = mat->pbr_metallic_roughness.base_color_texture.texture;
		if(t && t->image)
			return t->image;
	}
	if(mat->has_pbr_specular_glossiness && mat->pbr_specular_glossiness.diffuse_texture.texture)
	{
		cgltf_texture *t = mat->pbr_specular_glossiness.diffuse_texture.texture;
		if(t && t->image)
			return t->image;
	}
	return NULL;
}

typedef struct CountCtx
{
	size_t verts;
	size_t indices;
	size_t submeshes;
	int any_tris;
} CountCtx;

static void count_primitive(cgltf_primitive *prim, CountCtx *c)
{
	const cgltf_accessor *pos;

	if(prim->type != cgltf_primitive_type_triangles)
		return;
	if(prim->has_draco_mesh_compression)
		return;
	pos = cgltf_find_accessor(prim, cgltf_attribute_type_position, 0);
	if(!pos || pos->type != cgltf_type_vec3)
		return;
	c->any_tris = 1;
	c->verts += (size_t)pos->count;
	c->submeshes += 1u;
	if(prim->indices)
		c->indices += (size_t)prim->indices->count;
	else
		c->indices += (size_t)pos->count;
}

static void visit_count(cgltf_node *node, CountCtx *c)
{
	cgltf_size pi, i;

	if(node->mesh)
	{
		for(pi = 0; pi < node->mesh->primitives_count; pi++)
			count_primitive(&node->mesh->primitives[pi], c);
	}
	for(i = 0; i < node->children_count; i++)
		visit_count(node->children[i], c);
}

static void count_mesh_fallback(cgltf_mesh *mesh, CountCtx *c)
{
	cgltf_size pi;
	for(pi = 0; pi < mesh->primitives_count; pi++)
		count_primitive(&mesh->primitives[pi], c);
}

typedef struct FillCtx
{
	float *pos;
	float *nrm;
	float *uv;
	unsigned int *idx;
	size_t vbase;
	size_t ibase;
	RubikSubmesh *submeshes;
	size_t submesh_used;
	unsigned char **texture_rgba_list;
	int *texture_width_list;
	int *texture_height_list;
	const cgltf_image **texture_images;
	size_t texture_count;
	size_t texture_capacity;
	const char *gltf_path;
	cgltf_data *data;
} FillCtx;

static unsigned int ensure_white_texture(FillCtx *f)
{
	size_t i;
	for(i = 0; i < f->texture_count; i++)
	{
		if(f->texture_images[i] == NULL)
			return (unsigned int)i;
	}
	if(f->texture_count >= f->texture_capacity)
		return 0u;
	f->texture_images[f->texture_count] = NULL;
	f->texture_rgba_list[f->texture_count] = make_white_pixel();
	if(!f->texture_rgba_list[f->texture_count])
		return 0u;
	f->texture_width_list[f->texture_count] = 1;
	f->texture_height_list[f->texture_count] = 1;
	f->texture_count++;
	return (unsigned int)(f->texture_count - 1u);
}

static unsigned int ensure_texture_for_material(FillCtx *f, cgltf_material *mat)
{
	cgltf_image *img = pick_base_color_image(mat);
	size_t i;
	unsigned char *rgba;
	int w, h;

	if(!img)
		return ensure_white_texture(f);

	for(i = 0; i < f->texture_count; i++)
	{
		if(f->texture_images[i] == img)
			return (unsigned int)i;
	}

	if(f->texture_count >= f->texture_capacity)
		return ensure_white_texture(f);

	rgba = load_image_rgba(f->data, img, f->gltf_path, &w, &h);
	if(!rgba)
		return ensure_white_texture(f);

	f->texture_images[f->texture_count] = img;
	f->texture_rgba_list[f->texture_count] = rgba;
	f->texture_width_list[f->texture_count] = w;
	f->texture_height_list[f->texture_count] = h;
	f->texture_count++;
	return (unsigned int)(f->texture_count - 1u);
}

static int append_primitive(cgltf_node *node, cgltf_primitive *prim, float *world, FillCtx *f)
{
	const cgltf_accessor *acc_pos;

	(void)node;
	const cgltf_accessor *acc_nrm;
	const cgltf_accessor *acc_uv;
	cgltf_int uv_set = 0;
	cgltf_size vi, ti;
	float p[3], n[3], uv[2];
	cgltf_size vcount;
	cgltf_size icount;
	size_t first_index;
	unsigned int tex_index;

	if(prim->type != cgltf_primitive_type_triangles || prim->has_draco_mesh_compression)
		return 0;

	acc_pos = cgltf_find_accessor(prim, cgltf_attribute_type_position, 0);
	if(!acc_pos || acc_pos->type != cgltf_type_vec3)
		return 0;

	if(prim->material && prim->material->has_pbr_metallic_roughness &&
	   prim->material->pbr_metallic_roughness.base_color_texture.texture)
		uv_set = prim->material->pbr_metallic_roughness.base_color_texture.texcoord;
	else if(prim->material && prim->material->has_pbr_specular_glossiness &&
	        prim->material->pbr_specular_glossiness.diffuse_texture.texture)
		uv_set = prim->material->pbr_specular_glossiness.diffuse_texture.texcoord;

	acc_nrm = cgltf_find_accessor(prim, cgltf_attribute_type_normal, 0);
	acc_uv = cgltf_find_accessor(prim, cgltf_attribute_type_texcoord, uv_set);
	if(!acc_uv)
		acc_uv = cgltf_find_accessor(prim, cgltf_attribute_type_texcoord, 0);

	vcount = acc_pos->count;
	first_index = f->ibase;

	for(vi = 0; vi < vcount; vi++)
	{
		if(!cgltf_accessor_read_float(acc_pos, vi, p, 3))
			return -1;
		mat4_mul_vec3(world, p, f->pos + (f->vbase + vi) * 3u);

		if(acc_nrm && acc_nrm->type == cgltf_type_vec3)
		{
			if(!cgltf_accessor_read_float(acc_nrm, vi, n, 3))
				return -1;
			mat3_inv_transpose_apply_normal(world, n, f->nrm + (f->vbase + vi) * 3u);
		}
		else
		{
			float up[3] = {0.0f, 1.0f, 0.0f};
			mat3_inv_transpose_apply_normal(world, up, f->nrm + (f->vbase + vi) * 3u);
		}

		if(acc_uv && (acc_uv->type == cgltf_type_vec2 || acc_uv->type == cgltf_type_vec3))
		{
			if(!cgltf_accessor_read_float(acc_uv, vi, uv, 2))
				return -1;
			f->uv[(f->vbase + vi) * 2u + 0u] = uv[0];
			f->uv[(f->vbase + vi) * 2u + 1u] = uv[1];
		}
		else
		{
			f->uv[(f->vbase + vi) * 2u + 0u] = 0.0f;
			f->uv[(f->vbase + vi) * 2u + 1u] = 0.0f;
		}
	}

	if(prim->indices)
	{
		icount = prim->indices->count;
		for(ti = 0; ti < icount; ti++)
		{
			cgltf_size ix = cgltf_accessor_read_index(prim->indices, ti);
			f->idx[f->ibase + ti] = (unsigned int)(f->vbase + ix);
		}
	}
	else
	{
		icount = vcount;
		for(ti = 0; ti < icount; ti++)
			f->idx[f->ibase + ti] = (unsigned int)(f->vbase + ti);
	}

	tex_index = ensure_texture_for_material(f, prim->material);
	f->submeshes[f->submesh_used].first_index = (unsigned int)first_index;
	f->submeshes[f->submesh_used].index_count = (unsigned int)icount;
	f->submeshes[f->submesh_used].texture_index = tex_index;
	f->submesh_used++;

	f->vbase += vcount;
	f->ibase += icount;
	return 0;
}

static void visit_fill(cgltf_node *node, FillCtx *f)
{
	cgltf_float w[16];
	cgltf_size pi, i;

	cgltf_node_transform_world(node, w);

	if(node->mesh)
	{
		for(pi = 0; pi < node->mesh->primitives_count; pi++)
		{
			if(append_primitive(node, &node->mesh->primitives[pi], w, f) != 0)
				return;
		}
	}
	for(i = 0; i < node->children_count; i++)
		visit_fill(node->children[i], f);
}

static void fill_mesh_fallback(cgltf_mesh *mesh, float *world, FillCtx *f)
{
	cgltf_size pi;
	mat4_identity(world);
	for(pi = 0; pi < mesh->primitives_count; pi++)
		append_primitive(NULL, &mesh->primitives[pi], world, f);
}

void rubik_free_cpu_mesh(RubikCpuMesh *m)
{
	unsigned int i;
	if(!m)
		return;
	free(m->positions);
	free(m->normals);
	free(m->tangents);
	free(m->uvs);
	free(m->indices);
	free(m->submeshes);
	if(m->texture_rgba_list)
	{
		for(i = 0; i < m->texture_count; i++)
			free(m->texture_rgba_list[i]);
	}
	free(m->texture_rgba_list);
	free(m->texture_width_list);
	free(m->texture_height_list);
	memset(m, 0, sizeof(*m));
}

int rubik_load_from_gltf_path(const char *scene_gltf_path, RubikCpuMesh *out, char *errbuf, size_t errbuf_size)
{
	cgltf_options options = {0};
	cgltf_data *data = NULL;
	cgltf_result res;
	cgltf_scene *scene;
	CountCtx cnt = {0, 0, 0, 0};
	FillCtx fill;
	float identity[16];
	cgltf_size ri;

	if(errbuf && errbuf_size)
		errbuf[0] = '\0';

	if(!scene_gltf_path || !out)
		return -1;

	memset(out, 0, sizeof(*out));

	if(strlen(scene_gltf_path) >= 1024u)
	{
		if(errbuf && errbuf_size)
			strncpy(errbuf, "Path too long", errbuf_size - 1);
		return -2;
	}

	res = cgltf_parse_file(&options, scene_gltf_path, &data);
	if(res != cgltf_result_success || !data)
	{
		if(errbuf && errbuf_size)
			snprintf(errbuf, errbuf_size, "cgltf_parse_file failed (%d)", (int)res);
		if(data)
			cgltf_free(data);
		return -3;
	}

	res = cgltf_load_buffers(&options, data, scene_gltf_path);
	if(res != cgltf_result_success)
		res = load_buffers_fallback(data, scene_gltf_path);

	if(res != cgltf_result_success)
	{
		if(errbuf && errbuf_size)
		{
			if(res == cgltf_result_file_not_found)
				strncpy(errbuf,
					"Buffer file not found (e.g. scene.bin). Place it next to the .gltf, one folder above, or the working directory.",
					errbuf_size - 1);
			else
				snprintf(errbuf, errbuf_size, "cgltf_load_buffers failed (%d)", (int)res);
			errbuf[errbuf_size - 1] = '\0';
		}
		cgltf_free(data);
		return -4;
	}

	scene = data->scene;
	if(!scene && data->scenes_count > 0)
		scene = &data->scenes[0];

	if(scene)
	{
		for(ri = 0; ri < scene->nodes_count; ri++)
			visit_count(scene->nodes[ri], &cnt);
	}
	else
	{
		cgltf_size mi;
		for(mi = 0; mi < data->meshes_count; mi++)
			count_mesh_fallback(&data->meshes[mi], &cnt);
	}

	if(!cnt.any_tris || cnt.verts == 0u || cnt.indices == 0u)
	{
		if(errbuf && errbuf_size)
			strncpy(errbuf, "No triangle meshes found (or missing POSITION). Draco-compressed meshes are not supported.", errbuf_size - 1);
		cgltf_free(data);
		return -5;
	}

	out->vertex_count = (unsigned int)cnt.verts;
	out->index_count = (unsigned int)cnt.indices;
	out->submesh_count = (unsigned int)cnt.submeshes;

	out->positions = (float *)malloc(sizeof(float) * 3u * cnt.verts);
	out->normals = (float *)malloc(sizeof(float) * 3u * cnt.verts);
	out->uvs = (float *)malloc(sizeof(float) * 2u * cnt.verts);
	out->tangents = NULL;
	out->indices = (unsigned int *)malloc(sizeof(unsigned int) * cnt.indices);
	out->submeshes = (RubikSubmesh *)malloc(sizeof(RubikSubmesh) * cnt.submeshes);
	out->texture_rgba_list = (unsigned char **)calloc((data->images_count + 1u), sizeof(unsigned char *));
	out->texture_width_list = (int *)calloc((data->images_count + 1u), sizeof(int));
	out->texture_height_list = (int *)calloc((data->images_count + 1u), sizeof(int));

	if(!out->positions || !out->normals || !out->uvs || !out->indices || !out->submeshes ||
	   !out->texture_rgba_list || !out->texture_width_list || !out->texture_height_list)
	{
		rubik_free_cpu_mesh(out);
		cgltf_free(data);
		if(errbuf && errbuf_size)
			strncpy(errbuf, "Out of memory", errbuf_size - 1);
		return -6;
	}

	memset(&fill, 0, sizeof(fill));
	fill.pos = out->positions;
	fill.nrm = out->normals;
	fill.uv = out->uvs;
	fill.idx = out->indices;
	fill.submeshes = out->submeshes;
	fill.submesh_used = 0u;
	fill.texture_rgba_list = out->texture_rgba_list;
	fill.texture_width_list = out->texture_width_list;
	fill.texture_height_list = out->texture_height_list;
	fill.texture_images = (const cgltf_image **)calloc((data->images_count + 1u), sizeof(cgltf_image *));
	fill.texture_count = 0u;
	fill.texture_capacity = (size_t)(data->images_count + 1u);
	fill.gltf_path = scene_gltf_path;
	fill.data = data;
	if(!fill.texture_images)
	{
		rubik_free_cpu_mesh(out);
		cgltf_free(data);
		if(errbuf && errbuf_size)
			strncpy(errbuf, "Out of memory", errbuf_size - 1);
		return -6;
	}

	if(scene)
	{
		for(ri = 0; ri < scene->nodes_count; ri++)
			visit_fill(scene->nodes[ri], &fill);
	}
	else
	{
		cgltf_size mi;
		mat4_identity(identity);
		for(mi = 0; mi < data->meshes_count; mi++)
			fill_mesh_fallback(&data->meshes[mi], identity, &fill);
	}

	if(fill.texture_count == 0u)
		ensure_white_texture(&fill);
	if(fill.texture_count == 0u || out->texture_rgba_list[0] == NULL)
	{
		free((void *)fill.texture_images);
		cgltf_free(data);
		rubik_free_cpu_mesh(out);
		if(errbuf && errbuf_size)
			strncpy(errbuf, "Failed to create fallback texture", errbuf_size - 1);
		return -7;
	}

	out->submesh_count = (unsigned int)fill.submesh_used;
	out->texture_count = (unsigned int)fill.texture_count;
	if(out->texture_count > 0u)
	{
		out->texture_rgba = out->texture_rgba_list[0];
		out->texture_width = out->texture_width_list[0];
		out->texture_height = out->texture_height_list[0];
	}

	free((void *)fill.texture_images);
	cgltf_free(data);
	data = NULL;
	mat4_identity(out->model_matrix);
	out->loaded = 1;
	return 0;
}
