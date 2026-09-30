#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_clouds fragment (Section 11)
// Voxel slab clouds stay blocky: soft shading only —
// bright tops, faint blue-grey undersides, gentle sun-side tint,
// subtle translucency. No volumetric noise, silhouette preserved.
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

uniform sampler2D gtexture;
uniform vec3 shadowLightPosition;

in vec2 texcoord;
in vec4 glcolor;
in vec3 viewNormal;
in vec3 viewPos;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < 0.01) discard;

    vec3 n = normalize(viewNormal);
    vec3 lightDir = normalize(shadowLightPosition);

    // tops bright marshmallow white; undersides faint blue-grey
    float topness = clamp(n.y, -1.0, 1.0);
    vec3 top = vec3(1.02, 1.03, 1.05);
    vec3 under = vec3(0.72, 0.78, 0.88) * 0.9;
    vec3 shade = mix(under, top, topness * 0.5 + 0.5);

    // gentle lighting from the sun side
    float sunSide = dot(n, lightDir) * 0.5 + 0.5;
    shade *= 0.88 + 0.18 * sunSide;

    vec3 color = tex.rgb * shade;
    // soft translucency: keep alpha but slightly softer edges
    float alpha = tex.a * 0.92;

    fragColor = vec4(color, alpha);
}
