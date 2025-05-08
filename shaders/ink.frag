#ifdef GL_ES
precision mediump float;
#endif

uniform bool u_addDrop;
uniform vec2 u_dropPos;
uniform vec4 u_dropCol;
uniform vec2 u_resolution;
uniform float u_dropRadius;
uniform sampler2D u_prevTexture;
uniform vec2 u_glitchXY;

out vec4 fragCol;

vec4 marble(sampler2D tex, vec2 res, vec2 pixel_pos, vec2 drop_pos, vec4 colour, float radius) {
    float dist = distance(pixel_pos, drop_pos);	

    if (dist < radius) {
		return colour;
    } else {
		float epsilon = 0.01;
		float factor = 1.0 - (radius * radius) / (dist * dist + epsilon);
		vec2 displaced_pos = (pixel_pos - drop_pos) * factor + drop_pos;

		return texture(tex, displaced_pos / res);
	}
}

void main() {
	vec2 fragCoord = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y);

	vec2 res = u_resolution + u_glitchXY * (u_resolution / 8.0);

	if (u_addDrop) {
	    fragCol = marble(u_prevTexture, res, fragCoord, u_dropPos, u_dropCol, u_dropRadius);
	} else {
	    fragCol = texture(u_prevTexture, fragCoord / res);
	}
}
