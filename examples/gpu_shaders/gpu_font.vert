#version 450

layout(location=0) in vec3 position;
layout(location=1) in vec4 color;
layout(location=2) in vec2 uv;

layout(set=1, binding=0) uniform Camera_Uniform_Buffer {
	mat4 projection_view;
	mat4 model;
};

layout(location=0) out vec4 out_color;
layout(location=1) out vec2 out_uv;

void main() {
    gl_Position = projection_view * model * vec4(position, 1.0);
    // gl_Position = vec4(position, 1.0);

    out_color = color;
    out_uv = uv;
}