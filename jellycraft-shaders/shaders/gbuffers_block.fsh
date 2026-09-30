#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_block fragment (block entities)
// Default jelly-base wet gloss (no mc_Entity for block entities).
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/materials.glsl"
#include "/lib/jelly.glsl"

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 dataOut;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;
uniform float far;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 viewNormal;
in vec3 viewPos;
in vec3 worldPos;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < 0.1) discard;

    JcMaterial m = jcMaterialById(10011.0);   // jelly_base default
    vec3 albedo = jcWetAlbedo(tex.rgb, m.wetness);

    vec3 viewDir = normalize(-viewPos);
    vec3 lightDir = normalize(shadowLightPosition);
    vec3 color = jcJellyShade(m, albedo, viewNormal, viewDir, lightDir,
                              lmcoord, worldPos.xz, frameTimeCounter);

    float dist = length(viewPos);
    float fog = smoothstep(far * 0.65, far * 0.98, dist);
    color = mix(color, vec3(0.75, 0.85, 0.95), fog * 0.9);

    // Block entities share the same thin jelly skin as terrain.
    fragColor = vec4(color, tex.a * (1.0 - BLOCK_TRANSLUCENCY * 0.01));
    dataOut = vec4(jcEncodeNormal(viewNormal), m.roughness, 1.0);
}
