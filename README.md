# gaussian-primitives

Shader Include for Godot 4+
* A small library of analytic, Gaussian-integrated binary primitives (step, pulse, and periodic pulsetrain)
* Designed for antialiased rendering of hard thresholds or SDF-based shapes
* Supports both implicit derivatives (`dFdx` / `dFdy`) and explicit differentiation
* Includes component-wise overloads for `float`, `vec2`, `vec3`, and `vec4`
* Comes with a demo project for Godot 4.6

[Supporting Desmos graph](https://www.desmos.com/calculator/g3mmfl34ve)

## 3D comparison - checkerboard stress-test
* For perspective-influenced signals, `SHARPNESS` offers a tradeoff between aliasing artifacts and a predictable blur

![Comparison 3D](/comparisons/comparison_3d.png)

## 2D comparison - animated stress tests
* In simple 2D scenes, aliasing is almost completely eliminated, with only a subtle and stable blur

![Comparison 2D](/comparisons/comparison_2d.gif)
