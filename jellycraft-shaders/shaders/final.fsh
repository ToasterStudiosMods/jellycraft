#version 330 compatibility
// ================================================================
// JELLYCRAFT — final fragment (Section 12 post chain, lite)
//  exposure → bloom (ring taps, threshold) → ACES tonemap →
//  restrained display transform → subtle vignette → dither.
// Never blurs the pixel grid: bloom is additive on highlights only.
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

layout(location = 0) out vec4 fragColor;

uniform sampler2D colortex0;

in vec2 texcoord;

void main() {
    vec3 color = texture(colortex0, texcoord).rgb;

#if BLOOM != 0
    // soft highlight bloom: 8-tap golden ring, threshold in HDR space
    vec3 bloomSum = vec3(0.0);
    float radius = 0.011;
    const float GOLDEN = 2.39996;
    for (int i = 0; i < 8; i++) {
        float a = float(i) * GOLDEN;
        vec2 offs = vec2(cos(a), sin(a)) * radius * (0.5 + 0.5 * fract(float(i) * 0.37));
        vec3 s = texture(colortex0, clamp(texcoord + offs, 0.001, 0.999)).rgb;
        bloomSum += max(s - 1.0, 0.0) + max(s - 0.85, 0.0) * 0.35;
    }
    bloomSum /= 8.0;
    color += bloomSum * (BLOOM_STRENGTH * 0.014);
#endif

    // Preserve Minecraft's daylight balance by default.  Jelly is conveyed by
    // deformation, refraction and highlights—not a mandatory yellow exposure.
    color *= EXPOSURE * 0.01;

    // ACES filmic tonemap
    color = jcAces(color);

    // Optional saturation is neutral at the default 100%.
    color = jcSaturation(color, SATURATION * 0.01);

    // gentle vignette
    vec2 v = texcoord - 0.5;
    color *= 1.0 - dot(v, v) * 0.22;

    // dither to kill banding
    color += (jcHash12(texcoord * vec2(1920.0, 1080.0)) - 0.5) / 255.0;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
