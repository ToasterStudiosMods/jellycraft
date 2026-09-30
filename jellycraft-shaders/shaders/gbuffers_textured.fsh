#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_textured fragment (particles — Section 1.5.5)
// Block-break blobs read as glossy jelly bits: saturated candy tint
// + a small specular lift. Alpha preserved for soft particles.
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;
in vec3 viewNormal;
in vec3 viewPos;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < 0.01) discard;
    vec3 color = tex.rgb;
#if VANILLA_MODE == 0
    color = jcSaturation(color * 1.10, 1.22);
    // gentle glossy lift facing the camera (blobby jelly bit)
    float facing = clamp(dot(normalize(viewNormal), normalize(-viewPos)), 0.0, 1.0);
    color += vec3(0.9, 1.0, 0.95) * pow(facing, 3.0) * 0.18;
#endif
    fragColor = vec4(color, tex.a);
}
