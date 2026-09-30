#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_skybasic fragment
// Sky/horizon/stars/void quads keep their vanilla vertex colors
// (stars survive!), graded toward the clean saturated jelly blue.
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

in vec4 glcolor;

void main() {
    vec3 color = glcolor.rgb;
#if VANILLA_MODE == 0
    // cleaner, more saturated blue; slightly brighter high-key sky
    color = jcSaturation(color * 1.06, 1.18);
#endif
    fragColor = vec4(color, 1.0);
}
