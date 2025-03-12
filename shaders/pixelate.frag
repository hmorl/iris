#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform int u_amount;

in vec2 fragTexCoord;
out vec4 fragCol;

void main()
{
    vec2 abs_coord = fragTexCoord * u_resolution;
    vec2 downsampled = floor(abs_coord / float(u_amount)) * float(u_amount);
    vec2 downsampled_norm = downsampled / u_resolution;
    fragCol = texture(u_texture, downsampled_norm);
}
