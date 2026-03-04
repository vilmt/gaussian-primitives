shader_type canvas_item;
#include "res://gaussian_primitives.gdshaderinc"

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(vec2(c, s), vec2(-s, c)) * v;
}

// SDF functions source: https://iquilezles.org/articles/distfunctions2d/
// SDF + Gradient functions source: https://iquilezles.org/articles/distgradfunctions2d/

vec3 circle_sdfg(vec2 a, float r, vec2 p) {
	vec2 pa = p - a;
	float d = length(pa);
	return vec3(d - r, pa / d);
}

float star_sdf(float r, vec2 p) {
    const float k1x = 0.809016994; // cos(π/ 5) = ¼(√5+1)
    const float k2x = 0.309016994; // sin(π/10) = ¼(√5-1)
    const float k1y = 0.587785252; // sin(π/ 5) = ¼√(10-2√5)
    const float k2y = 0.951056516; // cos(π/10) = ¼√(10+2√5)
    const float k1z = 0.726542528; // tan(π/ 5) = √(5-2√5)
    const vec2  v1  = vec2( k1x,-k1y);
    const vec2  v2  = vec2(-k1x,-k1y);
    const vec2  v3  = vec2( k2x,-k2y);
    
    p.x = abs(p.x);
    p -= 2.0*max(dot(v1,p),0.0)*v1;
    p -= 2.0*max(dot(v2,p),0.0)*v2;
    p.x = abs(p.x);
    p.y -= r;
    return length(p-v3*clamp(dot(p,v3),0.0,k1z*r)) * sign(p.y*v3.x-p.x*v3.y);
}

vec3 segment_sdfg(vec2 a, vec2 b, float r, vec2 p) {
	vec2 ba = b-a, pa = p-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	vec2 q = pa-h*ba;
	float d = length(q);
	return vec3(d-r,q/d);
}

vec3 heart_sdfg(vec2 p) {
    float sx = (p.x<0.0)?-1.0:1.0;
    p.x = abs(p.x);
 
    if ( p.y+p.x>1.0 ) {
        const float r = sqrt(2.0)/4.0;
        vec2 q0 = p - vec2(0.25,0.75);
        float l = length(q0);
        vec3 d = vec3(l-r, q0/l);
        d.y *= sx;
        return d;
    } else {
        vec2 q1 = p - vec2(0.0,1.0);      
        vec2 q2 = p - 0.5*max(p.x+p.y,0.0);
        vec3 d1 = vec3(dot(q1,q1),q1);
        vec3 d2 = vec3(dot(q2,q2),q2);
        vec3 d = (d1.x<d2.x) ? d1: d2;
        d.x = sqrt(d.x);
        d.yz /= d.x;
        d *= (p.x>p.y)?1.0:-1.0;
        d.y *= sx;
        return d;
    }
}

// https://iquilezles.org/articles/bandlimiting/

vec3 rainbow(float t) {
	const vec3 a = vec3(0.5, 0.5, 0.5);
	const vec3 b = vec3(0.5, 0.5, 0.5);
	const vec3 c = vec3(1.0, 1.0, 1.0);
	const vec3 d = vec3(0.00, 0.33, 0.67);
	vec3 x = TAU * (c * t + d);
	return a + b * cos(x) * smoothstep(TAU, 0.0, fwidth(x));
}

void fragment() {
	COLOR.rgb = vec3(0.0);
	
	const vec2 grid = vec2(2.0);
	vec2 uv = UV * grid;
	
	/*
	Calculating explicit derivatives by hand is recommended when unwanted discontinuities
	appear in the filtering. Most of the time, automatic differentiation is just as good.
	*/
	
	vec2 duvdx = dFdx(uv);
	vec2 duvdy = dFdy(uv);
	vec2 f_uv = floor(uv);
	int i = int(f_uv.y * grid.x + f_uv.x);
	uv = fract(uv);
	
	switch (i) {
		case 0:
			// c.x: circle signed distance
			// c.yz: gradient of distance with respect to uv
			vec3 c = circle_sdfg(vec2(0.5), 0.2, uv) * 20.0;
			float duty_cycle = sin((UV.x * 0.5 + TIME * 0.25) * TAU) * 0.5 + 0.5;
			
			// Use the chain rule to compute screen-space derivatives of the distance:
			// d(c.x)/dx = dot(dc/duv, duv/dx)
			// The last two arguments can be omitted at the cost of possible filtering artifacts
			float signal = pulsetrain_gaussian(duty_cycle, c.x, dot(c.yz, duvdx), dot(c.yz, duvdy));
			COLOR.rgb = vec3(signal);
			break;
		case 1:
			uv = vec2(uv.x, 1.0 - uv.y);
			
			float happy = abs(sin(TIME * TAU));
			
			vec2 star1_uv = rotate(uv - vec2(0.2, 0.6), sin(TIME * TAU) * 0.3);
			float star1 = star_sdf(0.1, star1_uv * (1.0 + happy * 0.3));
			
			vec2 star2_uv = rotate(uv - vec2(0.3, 0.2), sin((TIME + 0.33) * TAU) * 0.2);
			float star2 = star_sdf(0.2, star2_uv * (1.0 + happy * 0.2));
			
			vec2 star3_uv = rotate(uv - vec2(0.65, 0.65), sin((TIME + 0.66) * TAU) * 0.1);
			float star3 = star_sdf(0.3, star3_uv * (1.0 + happy * 0.1));
			
			float stars = min(min(star1, star2), star3);
			// Pattern does not reach the edge so passing derivatives is less important
			float signal1 = step_gaussian(0.0, -stars);
			COLOR.rgb = vec3(1.0, 1.0, 0.7) * vec3(signal1);
			break;
		case 2:
			uv = vec2(uv.x, 1.0 - uv.y);
			uv -= vec2(0.5, 0.2);
			
			float scale = 2.0 + cos(TIME * TAU) * 0.2;
			uv *= scale;
			duvdx *= scale;
			duvdx *= -scale;
			
			vec3 heart = abs(heart_sdfg(uv));
			heart = pow(heart, vec3(1.3));
			float falloff = smoothstep(0.25, 0.0, abs(heart.x));
			vec3 color = rainbow(heart.x + TIME * 0.5);
			heart *= 10.0;
			heart.x -= TIME * 1.0;
			float signal = pulsetrain_gaussian(0.5, heart.x, dot(heart.yz, duvdx), dot(heart.yz, duvdy));
			COLOR.rgb = color * signal * falloff;
			break;
		case 3:
			float l = sin((uv.x * 2.0 + TIME * 0.25) * TAU) * 0.5 + 0.5;
			float x = uv.y * 8.0 + TIME + sin((uv.x * 4.0 + TIME * 0.5 + uv.y * 2.0) * TAU) * 0.3;
			// Pattern is complicated so we use automatic differentiation.
			// Causes artifacts at edges.
			float signal = pulsetrain_gaussian(l, x);
			COLOR.rgb = vec3(signal);
			break;
	}
}
