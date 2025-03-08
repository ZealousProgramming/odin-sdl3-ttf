#version 450

layout (location = 0) in vec4 color;
layout (location = 1) in vec2 uv;

layout (set=2, binding=0) uniform sampler2D u_sampler;

layout (location = 0) out vec4 o_color;

void main() {

    o_color = texture(u_sampler, uv) * color;
}