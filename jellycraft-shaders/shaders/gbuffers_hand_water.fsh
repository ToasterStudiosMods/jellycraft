#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_hand fragment
// Skin: realistic warm subsurface + wet sheen (NOT jelly — Section 8).
// Glass tools (itemId 10001/10002, translucent head texture): clear
// jelly-glass with rim highlights and a composite refraction mask
// (refraction itself happens in composite using the opaque backup).
// colortex4 written only where the glass mask applies; skin writes
// zero alpha so the liquid mask beneath is preserved (blend math).
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/materials.glsl"
#include "/lib/jelly.glsl"
#include "/lib/sky.glsl"

/* RENDERTARGETS: 0,1,4 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 dataOut;
layout(location = 2) out vec4 gelOut;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec3 shadowLightPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 viewNormal;
in vec3 viewPos;
in float itmId;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;

    int id = int(itmId + 0.5);
    bool glassPart = (id == 10001 || id == 10002) && tex.a < 0.95;
    JcMaterial m = jcItemMaterial(id);

    vec3 viewDir = normalize(-viewPos);
    vec3 lightDir = normalize(shadowLightPosition);
    vec3 color;
    float outAlpha = tex.a;

    if (glassPart) {
        // ============ JELLY-GLASS TOOL HEAD (Section 9) ============
        float facing = clamp(dot(viewNormal, viewDir), 0.0, 1.0);
        vec3 body = tex.rgb * m.baseColor * 0.9;
        // thin-film-ish tint at edges (very subtle)
        body += m.subsurfaceColor * pow(1.0 - facing, 2.5) * m.edgeGlow * 0.5;

        vec3 ambient = vec3(1.00, 0.70, 0.45) * pow(lmcoord.x, 2.2) * 1.35
                     + vec3(0.82, 0.92, 1.00) * pow(lmcoord.y, 1.6) * 0.85 + 0.05;
        float glint = jcGgx(viewNormal, viewDir, lightDir, m.roughness) * 2.4
                    * clamp(lmcoord.y * 1.3 + 0.1, 0.0, 1.0);
        vec3 rim = vec3(0.85, 0.95, 1.0) * pow(1.0 - facing, 3.0) * m.edgeGlow * 0.9;
        float coat = m.clearcoat * jcFresnelF(facing, 0.04) * 0.45;

        color = body * (ambient * 0.9 + vec3(0.9, 0.95, 0.85)
                        * jcWrapDiffuse(max(dot(viewNormal, lightDir), 0.0), 0.3) * 0.6);
        color += vec3(1.0) * glint * 0.9;
        color += rim;
        color += vec3(0.9, 1.0, 0.98) * coat;

#if SPARKLE_STRENGTH != 0
        color += vec3(1.0) * jcSparkle(texcoord, 40.0, frameTimeCounter)
                * m.sparkleStrength * (SPARKLE_STRENGTH * 0.01);
#endif

        // refraction mask for the composite pass (opaque backup in colortex3)
        float refrMask = (REFRACTION != 0 ? m.refractionStrength * (REFRACTION_STRENGTH * 0.01) : 0.0);
        vec3 specForComposite = rim + vec3(1.0) * glint * 0.5;
        gelOut = vec4(specForComposite, clamp(refrMask, 0.0, 1.0));
    } else {
        // ============ SKIN & GENERIC HELD THINGS ============
        bool woodTool = (id == 10003);
        float wetness = woodTool ? 0.35 : (id == 0 ? 0.25 : m.wetness);  // skin: mild
        vec3 subColor = woodTool ? vec3(1.0, 0.62, 0.25) : m.subsurfaceColor;
        float subStr = woodTool ? 0.15 : m.subsurfaceStrength;

        vec3 albedo = tex.a < 0.05 ? tex.rgb : tex.rgb;   // keep texture
        albedo = jcWetAlbedo(albedo, wetness);

        JcMaterial sm = jcDefaultMaterial();
        sm.roughness = woodTool ? 0.30 : (id == 0 ? 0.42 : m.roughness);
        sm.specular = woodTool ? 0.40 : (id == 0 ? 0.35 : m.specular);
        sm.wetness = wetness;
        sm.clearcoat = woodTool ? 0.45 : 0.30;
        sm.clearcoatRoughness = 0.20;
        sm.subsurfaceStrength = subStr;
        sm.subsurfaceColor = subColor;
        sm.edgeGlow = 0.18;
        sm.sparkleStrength = 0.0;

        color = jcJellyShade(sm, albedo, viewNormal, viewDir, lightDir,
                             lmcoord, texcoord * 4.0, frameTimeCounter);
        gelOut = vec4(0.0);   // alpha 0 → does not disturb existing gel mask
        fragColor = vec4(color, outAlpha);
        // skin preserves the gel normal underneath (alpha 0 blend)
        dataOut = vec4(jcEncodeNormal(viewNormal), m.roughness, 0.0);
        return;
    }

    fragColor = vec4(color, outAlpha);
    dataOut = vec4(jcEncodeNormal(viewNormal), m.roughness, 1.0);
}
