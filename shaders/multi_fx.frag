#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D u_texture;
uniform vec2 u_resolution;

uniform bool u_enablePixelate;
uniform int u_pixelateAmount;

uniform bool u_enableWarp;
uniform vec2 u_warpPos;

in vec2 fragTexCoord;
out vec4 fragCol;

vec2 warp(vec2 p){
    // adapted from https://www.shadertoy.com/view/mdjyWK

    vec2 center=u_warpPos;

    float radius=.7;
    float strength=1.9;

    p-=center;

    float d=length(p);
    d/=radius;

    float dPow=pow(d,2.);    
    float dRev=strength/(1.+dPow);

    p*=dRev;
    p+=center;

    return p;
}

void main()
{
    vec2 uv = fragTexCoord;

    if (u_enablePixelate) {
        vec2 abs_coord = uv * u_resolution;
        vec2 downsampled = floor(abs_coord / float(u_pixelateAmount)) * float(u_pixelateAmount);
        uv = downsampled / u_resolution;
    }

    if (u_enableWarp) {
        uv = warp(uv);
    }

    fragCol = texture(u_texture, uv);
}
