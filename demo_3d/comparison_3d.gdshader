shader_type spatial;
#include "res://gaussian_primitives.gdshaderinc"

uniform sampler2D sampler: filter_linear_mipmap_anisotropic;

uniform vec3 scale = vec3(1.0);
uniform vec3 offset;
uniform int wrap_mode: hint_enum("Local", "Triplanar", "World Triplanar") = 1;

varying vec3 vertex_p;

// unfiltered pulsetrain
vec3 pulsetrain(vec3 duty, vec3 p) {
	vec3 p_f = p - round(p);
	return step(0.0, p_f + duty * 0.5) - step(0.0, p_f - duty * 0.5);
}

void vertex() {
	switch (wrap_mode) {
		case 0:
			vertex_p = (UV.xyy - offset) / scale;
			break;
		case 1:
			vertex_p = (VERTEX - offset) / scale;
			vertex_p.y *= -1.0;
			break;
		case 2:
			vertex_p = (MODEL_MATRIX * vec4(VERTEX - offset, 1.0)).xyz / scale;
			vertex_p.y *= -1.0;
			break;
	}
}

void fragment() {
	vec2 screen_uv = vec2(FRAGCOORD.xy) / vec2(VIEWPORT_SIZE);
	ALBEDO.rgb = vec3(0.0);
	
	// pulses are centered at integers, so we offset by 0.25
	vec3 pt1 = pulsetrain(vec3(0.5), vertex_p+0.25);
	float s1 = pt1.x + pt1.z - 2.0 * pt1.x * pt1.z;
	
	vec3 pt2 = pulsetrain_gaussian(vec3(0.5), vertex_p+0.25);
	float s2 = pt2.x + pt2.z - 2.0 * pt2.x * pt2.z;
	
	// Moving this into the if would cause undefined partial derivatives
	float s3 = texture(sampler, vertex_p.xz).r;
	
	if (screen_uv.x < 1.0 / 3.0) {
		ALBEDO = vec3(s1);
	} else if (screen_uv.x < 2.0 / 3.0) {
		ALBEDO = vec3(s2);
	} else {
		ALBEDO = vec3(s3);
	}
}
