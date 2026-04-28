#include "OGL_Common.h"
#include "rubik_gltf.h"

#include <stdlib.h>
#include <string.h>

static RubikCpuMesh s_cpu;
static GLuint s_prog = 0;
static GLuint s_vao = 0;
static GLuint s_vbo[3];
static GLuint s_ebo = 0;
static GLuint *s_textures = NULL;
static unsigned int s_textureCount = 0;
static GLint s_uMVP = -1;
static GLint s_uModel = -1;
static GLint s_uTex = -1;
static GLsizei s_indexCount = 0;
static RubikSubmesh *s_submeshes = NULL;
static unsigned int s_submeshCount = 0;
static int s_loaded = 0;
static float s_modelMatrix[16];
static DWORD s_rotateStartTick = 0;
static float s_modelScale = 5.0f;

static void mat4_scale_uniform(float m[16], float s)
{
	memset(m, 0, sizeof(float) * 16);
	m[0] = s;
	m[5] = s;
	m[10] = s;
	m[15] = 1.0f;
}

static const char *vsSrc =
	"#version 460 core\n"
	"layout(location = 0) in vec3 aPos;\n"
	"layout(location = 1) in vec3 aNormal;\n"
	"layout(location = 2) in vec2 aUv;\n"
	"uniform mat4 uMVP;\n"
	"uniform mat4 uModel;\n"
	"out vec3 vN;\n"
	"out vec2 vUv;\n"
	"void main() {\n"
	"  mat3 N = mat3(transpose(inverse(uModel)));\n"
	"  vN = normalize(N * aNormal);\n"
	"  vUv = aUv;\n"
	"  gl_Position = uMVP * vec4(aPos, 1.0);\n"
	"}\n";

static const char *fsSrc =
	"#version 460 core\n"
	"in vec3 vN;\n"
	"in vec2 vUv;\n"
	"uniform sampler2D uTex;\n"
	"out vec4 FragColor;\n"
	"void main() {\n"
	"  vec3 L = normalize(vec3(0.4, 0.75, 0.5));\n"
	"  float ndl = max(dot(normalize(vN), L), 0.12);\n"
	"  vec4 base = texture(uTex, vUv);\n"
	"  FragColor = vec4(base.rgb * ndl, base.a);\n"
	"}\n";

static GLuint compileGlsl(GLenum type, const char *src, const char *label)
{
	GLuint sh;
	GLint ok = 0;
	char log[2048];
	GLsizei n = 0;

	sh = glCreateShader(type);
	glShaderSource(sh, 1, &src, NULL);
	glCompileShader(sh);
	glGetShaderiv(sh, GL_COMPILE_STATUS, &ok);
	if(ok == GL_FALSE)
	{
		glGetShaderInfoLog(sh, (GLsizei)sizeof(log), &n, log);
		fprintf(gpFile, "%s compile: %s\n", label, log);
		glDeleteShader(sh);
		return 0;
	}
	return sh;
}

static int buildProgram(void)
{
	GLuint vs;
	GLuint fs;
	GLint linked = 0;
	char log[2048];
	GLsizei n = 0;

	vs = compileGlsl(GL_VERTEX_SHADER, vsSrc, "mesh_vs");
	fs = compileGlsl(GL_FRAGMENT_SHADER, fsSrc, "mesh_fs");
	if(!vs || !fs)
		return -1;
	s_prog = glCreateProgram();
	glAttachShader(s_prog, vs);
	glAttachShader(s_prog, fs);
	glLinkProgram(s_prog);
	glDeleteShader(vs);
	glDeleteShader(fs);
	glGetProgramiv(s_prog, GL_LINK_STATUS, &linked);
	if(!linked)
	{
		glGetProgramInfoLog(s_prog, (GLsizei)sizeof(log), &n, log);
		fprintf(gpFile, "mesh link: %s\n", log);
		glDeleteProgram(s_prog);
		s_prog = 0;
		return -1;
	}
	s_uMVP = glGetUniformLocation(s_prog, "uMVP");
	s_uModel = glGetUniformLocation(s_prog, "uModel");
	s_uTex = glGetUniformLocation(s_prog, "uTex");
	return 0;
}

int OGL_ModelInit(void)
{
	char err[512];
	int rc;
	const char *modelCandidates[] = {
		// "1970_dodge_challenger_rt\\scene.gltf",
		// "assets\\1970_dodge_challenger_rt\\scene.gltf",
		"assets\\scene.gltf"
	};
	int i;

	memset(&s_cpu, 0, sizeof(s_cpu));
	memset(s_vbo, 0, sizeof(s_vbo));
	if(s_submeshes)
	{
		free(s_submeshes);
		s_submeshes = NULL;
	}
	if(s_textures)
	{
		free(s_textures);
		s_textures = NULL;
	}
	s_submeshCount = 0;
	s_textureCount = 0;

	rc = -1;
	for(i = 0; i < (int)(sizeof(modelCandidates) / sizeof(modelCandidates[0])); i++)
	{
		rc = rubik_load_from_gltf_path(modelCandidates[i], &s_cpu, err, sizeof(err));
		if(rc == 0 && s_cpu.loaded)
		{
			fprintf(gpFile, "Loaded model: %s\n", modelCandidates[i]);
			break;
		}
	}
	if(rc != 0 || !s_cpu.loaded)
	{
		MessageBoxA(NULL, err[0] ? err : "rubik_load failed", "Model_Loading", MB_OK | MB_ICONWARNING);
		fprintf(gpFile, "rubik_load: %s\n", err);
		return -1;
	}

	if(buildProgram() != 0)
	{
		rubik_free_cpu_mesh(&s_cpu);
		MessageBoxA(NULL, "Shader build failed (see Log.txt)", "Model_Loading", MB_OK | MB_ICONERROR);
		return -1;
	}

	glGenVertexArrays(1, &s_vao);
	glBindVertexArray(s_vao);

	glGenBuffers(3, s_vbo);

	glBindBuffer(GL_ARRAY_BUFFER, s_vbo[0]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 3u * s_cpu.vertex_count, s_cpu.positions, GL_STATIC_DRAW);
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(0);

	glBindBuffer(GL_ARRAY_BUFFER, s_vbo[1]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 3u * s_cpu.vertex_count, s_cpu.normals, GL_STATIC_DRAW);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(1);

	glBindBuffer(GL_ARRAY_BUFFER, s_vbo[2]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * 2u * s_cpu.vertex_count, s_cpu.uvs, GL_STATIC_DRAW);
	glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, NULL);
	glEnableVertexAttribArray(2);

	glGenBuffers(1, &s_ebo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, s_ebo);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * s_cpu.index_count, s_cpu.indices, GL_STATIC_DRAW);

	glBindVertexArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	s_indexCount = (GLsizei)s_cpu.index_count;
	s_submeshCount = s_cpu.submesh_count;
	if(s_submeshCount > 0u)
	{
		s_submeshes = (RubikSubmesh *)malloc(sizeof(RubikSubmesh) * s_submeshCount);
		if(!s_submeshes)
		{
			rubik_free_cpu_mesh(&s_cpu);
			MessageBoxA(NULL, "Out of memory (submeshes)", "Model_Loading", MB_OK | MB_ICONERROR);
			return -1;
		}
		memcpy(s_submeshes, s_cpu.submeshes, sizeof(RubikSubmesh) * s_submeshCount);
	}

	s_textureCount = s_cpu.texture_count ? s_cpu.texture_count : 1u;
	s_textures = (GLuint *)calloc(s_textureCount, sizeof(GLuint));
	if(!s_textures)
	{
		rubik_free_cpu_mesh(&s_cpu);
		if(s_submeshes)
		{
			free(s_submeshes);
			s_submeshes = NULL;
		}
		MessageBoxA(NULL, "Out of memory (textures)", "Model_Loading", MB_OK | MB_ICONERROR);
		return -1;
	}
	glGenTextures((GLsizei)s_textureCount, s_textures);
	for(i = 0; i < (int)s_textureCount; i++)
	{
		unsigned char *rgba = s_cpu.texture_rgba_list ? s_cpu.texture_rgba_list[i] : s_cpu.texture_rgba;
		int tw = s_cpu.texture_width_list ? s_cpu.texture_width_list[i] : s_cpu.texture_width;
		int th = s_cpu.texture_height_list ? s_cpu.texture_height_list[i] : s_cpu.texture_height;
		glBindTexture(GL_TEXTURE_2D, s_textures[i]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, tw, th, 0, GL_RGBA, GL_UNSIGNED_BYTE, rgba);
		glGenerateMipmap(GL_TEXTURE_2D);
	}
	glBindTexture(GL_TEXTURE_2D, 0);

	memcpy(s_modelMatrix, s_cpu.model_matrix, sizeof(s_modelMatrix));
	rubik_free_cpu_mesh(&s_cpu);

	s_loaded = 1;
	return 0;
}

void OGL_ModelShutdown(void)
{
	if(!s_loaded)
		return;

	if(s_textures && s_textureCount > 0u)
	{
		glDeleteTextures((GLsizei)s_textureCount, s_textures);
		free(s_textures);
		s_textures = NULL;
		s_textureCount = 0;
	}
	if(s_ebo)
	{
		glDeleteBuffers(1, &s_ebo);
		s_ebo = 0;
	}
	if(s_vbo[0])
		glDeleteBuffers(3, s_vbo);
	memset(s_vbo, 0, sizeof(s_vbo));
	if(s_vao)
	{
		glDeleteVertexArrays(1, &s_vao);
		s_vao = 0;
	}
	if(s_prog)
	{
		glDeleteProgram(s_prog);
		s_prog = 0;
	}
	if(s_submeshes)
	{
		free(s_submeshes);
		s_submeshes = NULL;
	}
	s_submeshCount = 0;
	s_loaded = 0;
	s_indexCount = 0;
	s_rotateStartTick = 0;
}

void OGL_ModelDraw(void)
{
	float model[16];
	float rot[16];
	float scl[16];
	float modelScaled[16];
	float view[16];
	float pv[16];
	float mvp[16];
	float sec;
	float rx, ry, rz;
	unsigned int si;

	if(!s_loaded || !s_prog)
		return;

	if(s_rotateStartTick == 0)
		s_rotateStartTick = GetTickCount();
	/* Time in seconds; different rates on X/Y/Z for smooth tumbling (deg/s). */
	sec = (float)(GetTickCount() - s_rotateStartTick) * 0.001f;
	rx = sec * 9.0f;
	ry = sec * 13.0f;
	rz = sec * 7.0f;
	math_mat4_rotate_euler_deg(rot, rx, ry, rz);
	math_mat4_multiply(model, rot, s_modelMatrix);
	mat4_scale_uniform(scl, s_modelScale);
	math_mat4_multiply(modelScaled, scl, model);
	math_mat4_translate(view, 0.0f, 0.0f, -2.0f);
	math_mat4_multiply(pv, presepectiveProjectionMatrix, view);
	math_mat4_multiply(mvp, pv, modelScaled);

	glUseProgram(s_prog);
	glUniformMatrix4fv(s_uMVP, 1, GL_FALSE, mvp);
	glUniformMatrix4fv(s_uModel, 1, GL_FALSE, modelScaled);
	glUniform1i(s_uTex, 0);

	glBindVertexArray(s_vao);
	glActiveTexture(GL_TEXTURE0);
	if(s_submeshCount > 0u && s_textures && s_textureCount > 0u)
	{
		for(si = 0; si < s_submeshCount; si++)
		{
			const RubikSubmesh *sm = &s_submeshes[si];
			unsigned int ti = sm->texture_index;
			if(ti >= s_textureCount)
				ti = 0u;
			glBindTexture(GL_TEXTURE_2D, s_textures[ti]);
			glDrawElements(GL_TRIANGLES, (GLsizei)sm->index_count, GL_UNSIGNED_INT, (const void *)((size_t)sm->first_index * sizeof(unsigned int)));
		}
	}
	else if(s_textures && s_textureCount > 0u)
	{
		glBindTexture(GL_TEXTURE_2D, s_textures[0]);
		glDrawElements(GL_TRIANGLES, s_indexCount, GL_UNSIGNED_INT, NULL);
	}
	glBindVertexArray(0);

	glUseProgram(0);
}
