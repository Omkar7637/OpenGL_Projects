#ifndef MATH_BRIDGE_H
#define MATH_BRIDGE_H

/*
 * Single C++ translation unit (math_bridge.cpp) using vmath; all other code calls these
 * as plain C. Column-major 4x4 matrices (OpenGL), 16 floats.
 */

#ifdef __cplusplus
extern "C" {
#endif

void math_mat4_identity(float m[16]);
void math_mat4_perspective(float m[16], float fovy_deg, float aspect, float znear, float zfar);
void math_mat4_translate(float m[16], float x, float y, float z);
void math_mat4_multiply(float r[16], const float a[16], const float b[16]);
void math_mat4_copy(float d[16], const float s[16]);
/* angle_degrees: vmath rotate() uses degrees, axis Y = (0,1,0). */
void math_mat4_rotate_y_deg(float m[16], float angle_degrees);
/* Euler XYZ in degrees (vmath: Rz * Ry * Rx). */
void math_mat4_rotate_euler_deg(float m[16], float deg_x, float deg_y, float deg_z);

#ifdef __cplusplus
}
#endif

#endif
