// "Wabern" of the invisible world (docs/game_design/release_roadmap.md §3.6).
//
// One pass per chunk. uState holds the cells' spiritual states as a tiny
// texture (one pixel per cell plus a two-cell border from the neighbours,
// R = darkness, G = light), sampled bicubically (B-spline from four linear
// lookups) so transitions flow instead of showing the cell grid – plain
// linear filtering left visible square edges (playtest 2026-10-31). Animated domain-warped noise makes
// dark areas swirl, drag streaks and pulse slowly; light areas shimmer
// calmly. Noise runs in world space (uOffset), so neighbouring chunks
// continue seamlessly.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // chunk size in px
uniform float uTime;     // seconds
uniform vec2 uOffset;    // chunk origin in world px
uniform float uCells;    // cells per side (16)
uniform sampler2D uState;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Cubic B-spline weights for a fractional position [v].
vec4 cubic(float v) {
  vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
  vec4 s = n * n * n;
  float x = s.x;
  float y = s.y - 4.0 * s.x;
  float z = s.z - 4.0 * s.y + 6.0 * s.x;
  float w = 6.0 - x - y - z;
  return vec4(x, y, z, w) * (1.0 / 6.0);
}

// Smooth lookup of uState (size [texSize] px) at [uv]: four bilinear
// fetches combined into a cubic B-spline – no visible cell grid. (Web
// shaders cannot take a sampler as a parameter.)
vec4 stateBicubic(vec2 uv, float texSize) {
  vec2 coord = uv * texSize - 0.5;
  vec2 f = fract(coord);
  coord -= f;
  vec4 xc = cubic(f.x);
  vec4 yc = cubic(f.y);
  vec4 c = coord.xxyy + vec2(-0.5, 1.5).xyxy;
  vec4 s = vec4(xc.xz + xc.yw, yc.xz + yc.yw);
  vec4 o = (c + vec4(xc.yw, yc.yw) / s) / texSize;
  vec4 s0 = texture(uState, o.xz);
  vec4 s1 = texture(uState, o.yz);
  vec4 s2 = texture(uState, o.xw);
  vec4 s3 = texture(uState, o.yw);
  float sx = s.x / (s.x + s.y);
  float sy = s.z / (s.z + s.w);
  return mix(mix(s3, s2, sx), mix(s1, s0, sx), sy);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p = p * 2.03 + vec2(17.1, 9.2);
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 local = FlutterFragCoord().xy;
  vec2 world = (uOffset + local) / 220.0;
  float t = uTime;

  // Domain warping: two layers of noise bend the lookup.
  vec2 q = vec2(fbm(world + vec2(0.0, t * 0.05)), fbm(world + vec2(5.2, 1.3) - t * 0.04));
  vec2 r = vec2(fbm(world + 3.0 * q + vec2(1.7, 9.2) + t * 0.07),
                fbm(world + 3.0 * q + vec2(8.3, 2.8) - t * 0.06));
  float swirl = fbm(world + 2.5 * r);

  // State lookup, warped (up to about a cell) so borders breathe and
  // wander instead of following the cell grid.
  vec2 uv = local / uSize;
  float n = uCells + 4.0;
  vec2 warp = (r - 0.5) * (3.0 / n);
  vec2 st = (uv * uCells + 2.0) / n + warp;
  vec4 s = stateBicubic(st, n);
  float dark = s.r;
  float light = s.g;

  vec3 neutral = vec3(0.13, 0.13, 0.14);

  // Darkness: near-black with crimson streaks that crawl and pulse.
  float pulse = 0.85 + 0.15 * sin(t * 1.3 + swirl * 6.0);
  float streak = smoothstep(0.38, 0.8, swirl);
  vec3 darkCol = mix(vec3(0.02, 0.0, 0.01), vec3(0.48, 0.02, 0.05), streak * pulse);
  darkCol *= 0.6 + 0.6 * fbm(world * 3.0 - r * 2.0 + t * 0.15);

  // Light: deep green with a calm shimmer.
  float shimmer = 0.5 + 0.5 * sin(t * 0.8 + fbm(world * 2.0 + q) * 8.0);
  vec3 lightCol = mix(vec3(0.03, 0.17, 0.05), vec3(0.10, 0.34, 0.12), shimmer * 0.6);

  vec3 col = neutral;
  col = mix(col, darkCol, smoothstep(0.0, 0.55, dark));
  col = mix(col, lightCol, smoothstep(0.0, 0.55, light));

  fragColor = vec4(col, 1.0);
}
