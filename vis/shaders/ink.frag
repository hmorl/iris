#version 330

uniform bool u_addDrop;
uniform vec2 u_dropPos;
uniform bool u_touch;
uniform vec2 u_touchPos;
uniform vec4 u_dropCol;
uniform sampler2D u_prevTexture;

out vec4 fragCol;

vec4 marble(vec2 pixel_pos, vec2 drop_pos, vec4 colour, float radius) {
    float dist = distance(pixel_pos, drop_pos);	

    if (dist < radius) {
		return colour;
    } else {
		float epsilon = 0.01;
		float factor = 1 - (radius * radius) / (dist * dist + epsilon);
		vec2 displaced_pos = (pixel_pos - drop_pos) * factor + drop_pos;

		return texelFetch(u_prevTexture, ivec2(displaced_pos), 0);
	}
}

void main() {
	vec2 fragCoord = gl_FragCoord.xy;
	float dropRadius = 20.0;

	if (u_addDrop) {
	    fragCol = marble(fragCoord, u_dropPos, u_dropCol, dropRadius);
	} else {
	    fragCol = texelFetch(u_prevTexture, ivec2(fragCoord), 0);
	}
}
