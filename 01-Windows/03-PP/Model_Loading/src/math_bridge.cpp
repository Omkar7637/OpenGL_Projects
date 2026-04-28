/*
 * Only this file includes vmath (C++). Exposes C-callable matrix helpers for the rest of the app.
 */

#include "math_bridge.h"

#include "vmath.h"

#include <cstring>

using namespace vmath;

extern "C" void math_mat4_identity(float m[16])
{
	mat4 I = mat4::identity();
	std::memcpy(m, &I, sizeof(float) * 16);
}

extern "C" void math_mat4_perspective(float m[16], float fovy_deg, float aspect, float znear, float zfar)
{
	mat4 P = perspective(fovy_deg, aspect, znear, zfar);
	std::memcpy(m, &P, sizeof(float) * 16);
}

extern "C" void math_mat4_translate(float m[16], float x, float y, float z)
{
	mat4 T = translate(x, y, z);
	std::memcpy(m, &T, sizeof(float) * 16);
}

extern "C" void math_mat4_multiply(float r[16], const float a[16], const float b[16])
{
	mat4 A;
	mat4 B;
	std::memcpy(&A, a, sizeof(float) * 16);
	std::memcpy(&B, b, sizeof(float) * 16);
	mat4 R = A * B;
	std::memcpy(r, &R, sizeof(float) * 16);
}

extern "C" void math_mat4_copy(float d[16], const float s[16])
{
	std::memcpy(d, s, sizeof(float) * 16);
}

extern "C" void math_mat4_rotate_y_deg(float m[16], float angle_degrees)
{
	mat4 R = rotate(angle_degrees, 0.0f, 1.0f, 0.0f);
	std::memcpy(m, &R, sizeof(float) * 16);
}

extern "C" void math_mat4_rotate_euler_deg(float m[16], float deg_x, float deg_y, float deg_z)
{
	mat4 R = rotate(deg_x, deg_y, deg_z);
	std::memcpy(m, &R, sizeof(float) * 16);
}
