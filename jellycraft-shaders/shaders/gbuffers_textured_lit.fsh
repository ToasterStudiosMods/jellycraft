#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_textured_lit fragment (lit particles, rain)
// Jelly-tinted, glossy particles; rain reads as thin gel streaks.
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

uniform sampler2D gtexture;
uniform sampler2D lightmap;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 viewNormal;
in vec3 viewPos;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < 0.01) discard;
    vec3 color = tex.rgb;
#if VANILLA_MODE == 0
    color *= 0.85 + 0.5 * pow(lmcoord.y, 1.4);
    color = jcSaturation(color * 1.08, 1.15);
    float facing = clamp(dot(normalize(viewNormal), normalize(-viewPos)), 0.0, 1.0);
    color += vec3(0.9, 1.0, 0.95) * pow(facing, 3.0) * 0.16;
#endif
    fragColor = vec4(color, tex.a);
}
