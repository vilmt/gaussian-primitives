# gaussian-primitives

Shader Include for Godot 4+
* A small library of analytic, Gaussian-integrated binary primitives (step, pulse, and periodic pulsetrain)
* Designed for antialiased rendering of hard thresholds or SDF-based shapes
* Supports both implicit derivatives (`dFdx` / `dFdy`) and explicit differentiation
* Includes component-wise overloads for `float`, `vec2`, `vec3`, and `vec4`
* Comes with a demo project for Godot 4.6

[Supporting Desmos graph](https://www.desmos.com/calculator/g3mmfl34ve)

## 3D comparison - checkerboard stress-test
* At close viewing distances, visual quality is comparable or better than the texture-based checkerboard
* At far distances, the analytic filter produces a slightly blurrier result with reduced aliasing and moiré interference
![Comparison 3D](/comparisons/comparison_3d.png)

## 2D comparison - animated stress tests
* With `SHARPNESS = 1.0`, aliasing is almost completely eliminated, with only a subtle and stable blur
* Reducing `SHARPNESS` to `0.5` fully suppresses aliasing at the cost of additional smoothing
![Comparison 2D](/comparisons/comparison_2d.gif)
