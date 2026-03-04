/*
Gaussian Primitives library by vilmt

* A collection of Gaussian-convolved binary primitives (step, pulse, pulsetrain)
* Includes functions with and without explicit derivatives
* Includes all component-wise types from float to vec4
* Useful when combined with signed distance fields
*/

// Larger = sharper transitions, smaller = more smoothing (e.g. 0.5 removes pulsetrain aliasing)
#define SHARPNESS 1.0

// Magnitude of screen-space gradient (filter footprint w)
#define DERIV_LENGTH(dpdx, dpdy) max(sqrt(dpdx * dpdx + dpdy * dpdy), 1e-6)
//#define DERIV_LENGTH(dpdx, dpdy) max(max(abs(dpdx), abs(dpdy)), 1e-6)

// Approximate Gaussian CDF: integral from -∞ to p of exp(-PI * x * x)

// 2% max error, still negligible
#define _Z_DEFINE(type) \
type Z(type p) { \
	return 0.5 + 0.5 * tanh(2.133 * p); \
}
//#define _Z_DEFINE(type) \
//type Z(type p) { \
	//const float c = 0.280955440565; \
	//return 0.5 + 0.5 * tanh(2.0 * p * (1.0 + c * p * p)); \
//}

_Z_DEFINE(float)
_Z_DEFINE(vec2)
_Z_DEFINE(vec3)
_Z_DEFINE(vec4)

// Step: 1 when p > edge, else 0

#define _STEP_DEFINE(type) \
type step_gaussian(type edge, type p) { \
	type inv_w = SHARPNESS / DERIV_LENGTH(dFdx(p), dFdy(p)); \
	return Z(inv_w * (p - edge)); \
}

#define _STEP_DEFINE_EXPLICIT(type) \
type step_gaussian(type edge, type p, type dpdx, type dpdy) { \
	type inv_w = SHARPNESS / DERIV_LENGTH(dpdx, dpdy); \
	return Z(inv_w * (p - edge)); \
}

// Pulse: 1 when edge_a < p < edge_b, else 0

#define _PULSE_DEFINE(type) \
type pulse_gaussian(type edge_a, type edge_b, type p) { \
	type inv_w = SHARPNESS / DERIV_LENGTH(dFdx(p), dFdy(p)); \
	return Z(inv_w * (p - edge_a)) - Z(inv_w * (p - edge_b)); \
}

#define _PULSE_DEFINE_EXPLICIT(type) \
type pulse_gaussian(type edge_a, type edge_b, type p, type dpdx, type dpdy) { \
	type inv_w = SHARPNESS / DERIV_LENGTH(dpdx, dpdy); \
	return Z(inv_w * (p - edge_a)) - Z(inv_w * (p - edge_b)); \
}

// Pulsetrain: 1 when there exists an integer k such that |p - k| < duty/2, else 0

/* Since we cannot compute an infinite sum, we sum only 5 pulses (k = -2..2) and
   blend to the average value (duty) when the filter footprint becomes large. */
#define FALLBACK 1.5 
#define BLEND_RANGE 0.01 // Does very little since error is small at fallback

#define _PULSETRAIN_DEFINE(type) \
type pulsetrain_gaussian(type duty, type p) { \
	type w = DERIV_LENGTH(dFdx(p), dFdy(p)) / SHARPNESS; \
	type inv_w = 1.0 / w; \
	type c = round(p); \
	type r = type(0.0); \
	for (int k = -2; k <= 2; k++) { \
		type pk = p - c + float(k); \
		r += Z(inv_w * (pk + duty * 0.5)) - Z(inv_w * (pk - duty * 0.5)); \
	} \
	return mix(r, duty, smoothstep(FALLBACK - BLEND_RANGE, FALLBACK, w)); \
}

#define _PULSETRAIN_DEFINE_EXPLICIT(type) \
type pulsetrain_gaussian(type duty, type p, type dpdx, type dpdy) { \
	type w = DERIV_LENGTH(dpdx, dpdy) / SHARPNESS; \
	type inv_w = 1.0 / w; \
	type c = round(p); \
	type r = type(0.0); \
	for (int k = -2; k <= 2; k++) { \
		type pk = p - c + float(k); \
		r += Z(inv_w * (pk + duty * 0.5)) - Z(inv_w * (pk - duty * 0.5)); \
	} \
	return mix(r, duty, smoothstep(FALLBACK - BLEND_RANGE, FALLBACK, w)); \
}

_STEP_DEFINE(float)
_STEP_DEFINE(vec2)
_STEP_DEFINE(vec3)
_STEP_DEFINE(vec4)

_STEP_DEFINE_EXPLICIT(float)
_STEP_DEFINE_EXPLICIT(vec2)
_STEP_DEFINE_EXPLICIT(vec3)
_STEP_DEFINE_EXPLICIT(vec4)

_PULSE_DEFINE(float)
_PULSE_DEFINE(vec2)
_PULSE_DEFINE(vec3)
_PULSE_DEFINE(vec4)

_PULSE_DEFINE_EXPLICIT(float)
_PULSE_DEFINE_EXPLICIT(vec2)
_PULSE_DEFINE_EXPLICIT(vec3)
_PULSE_DEFINE_EXPLICIT(vec4)

_PULSETRAIN_DEFINE(float)
_PULSETRAIN_DEFINE(vec2)
_PULSETRAIN_DEFINE(vec3)
_PULSETRAIN_DEFINE(vec4)

_PULSETRAIN_DEFINE_EXPLICIT(float)
_PULSETRAIN_DEFINE_EXPLICIT(vec2)
_PULSETRAIN_DEFINE_EXPLICIT(vec3)
_PULSETRAIN_DEFINE_EXPLICIT(vec4)
