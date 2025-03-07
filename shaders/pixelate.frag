#version 330

uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform int u_amount;

in vec2 fragTexCoord;
out vec4 fragCol;

void main()
{
    vec2 texelCoord = fragTexCoord * u_resolution;
    vec2 downsampled = floor(texelCoord / float(u_amount)) * float(u_amount);
    fragCol = texelFetch(u_texture, ivec2(downsampled), 0);
}
