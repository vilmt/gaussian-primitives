/*
Gaussian Primitives by vilmt

* A small library of analytic, Gaussian-integrated binary primitives (step, pulse, and periodic pulsetrain)
* Designed for antialiased rendering of hard thresholds or SDF-based shapes
* Supports both implicit derivatives (`dFdx` / `dFdy`) and explicit differentiation
* Includes component-wise overloads for `float`, `vec2`, `vec3`, and `vec4`
*/

// Larger = sharper transitions, smaller = more smoothing
#define SHARPNESS 0.7

// Magnitude of screen-space gradient (filter footprint w)
#define DERIV_LENGTH(dpdx, dpdy) max(sqrt(dpdx * dpdx + dpdy * dpdy), 1e-6)
//#define DERIV_LENGTH(dpdx, dpdy) max(max(abs(dpdx), abs(dpdy)), 1e-6)

// Approximate Gaussian CDF: integral from -∞ to p of exp(-PI * p * p)
// www.reddit.com/r/vulkan/comments/c4r7qx/erf_for_vulkan/
// TODO: find an even cheaper approximation. Precision can still be reduced almost for free.
#define _Z_DEFINE(type) \
type Z(type p) { \
	type a = abs(p); \
	type y = a * (a * (a * 0.02116217607 + 0.06389419205) + 0.06263162425) + 1.0; \
	y = y * y; \
	y = y * y; \
	y = y * y; \
	y = y * y; \
	y = y * y; \
	y = 1.0 - 1.0 / y; \
	return 0.5 + 0.5 * y * sign(p); \
}

_Z_DEFINE(float)
_Z_DEFINE(vec2)
_Z_DEFINE(vec3)
_Z_DEFINE(vec4)

// Step: 1 when p > edge, else 0

#define _STEP_DEFINE(type) \
type step_gaussian(type edge, type p) { \
	type dpdx = dFdx(p); \
	type dpdy = dFdy(p); \
	type inv_w = SHARPNESS / DERIV_LENGTH(dpdx, dpdy); \
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
	type dpdx = dFdx(p); \
	type dpdy = dFdy(p); \
	type inv_w = SHARPNESS / DERIV_LENGTH(dpdx, dpdy); \
	return Z(inv_w * (p - edge_a)) - Z(inv_w * (p - edge_b)); \
}

#define _PULSE_DEFINE_EXPLICIT(type) \
type pulse_gaussian(type edge_a, type edge_b, type p, type dpdx, type dpdy) { \
	type inv_w = SHARPNESS / DERIV_LENGTH(dpdx, dpdy); \
	return Z(inv_w * (p - edge_a)) - Z(inv_w * (p - edge_b)); \
}

// Pulsetrain: 1 when there exists an integer k such that |p - k| < duty/2, else 0

/* Since we cannot compute an infinite sum, we sum only 3 pulses (k = -1, 0, 1) and
   blend to the average value (duty) when the filter footprint becomes large. */

#define _PULSETRAIN_DEFINE(type) \
type pulsetrain_gaussian(type duty, type p) { \
	type dpdx = dFdx(p); \
	type dpdy = dFdy(p); \
	type w = DERIV_LENGTH(dpdx, dpdy) / SHARPNESS; \
	type inv_w = 1.0 / w, d = 0.5 * inv_w * duty; \
	p = inv_w * (p - round(p)); \
	type r = Z(p + inv_w + d) - Z(p + inv_w - d) \
		   + Z(p + d) - Z(p - d) \
		   + Z(p - inv_w + d) - Z(p - inv_w - d); \
	return mix(r, duty, smoothstep(1.1, 1.2, w)); \
}

#define _PULSETRAIN_DEFINE_EXPLICIT(type) \
type pulsetrain_gaussian(type duty, type p, type dpdx, type dpdy) { \
	type w = DERIV_LENGTH(dpdx, dpdy) / SHARPNESS; \
	type inv_w = 1.0 / w, d = 0.5 * inv_w * duty; \
	p = inv_w * (p - round(p)); \
	type r = Z(p + inv_w + d) - Z(p + inv_w - d) \
		   + Z(p + d) - Z(p - d) \
		   + Z(p - inv_w + d) - Z(p - inv_w - d); \
	return mix(r, duty, smoothstep(1.1, 1.2, w)); \
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
