#version 330

uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform int u_amount;

in vec2 fragTexCoord;
out vec4 fragCol;

void main()
{
    // vec2 fragCoord = gl_FragCoord.xy;
    vec2 st = vec2(ivec2(fragTexCoord * float(u_amount)) + 0.5) / float(u_amount);
    fragCol = texture(u_texture, st, 0);
}
