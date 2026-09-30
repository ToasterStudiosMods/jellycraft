#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_water fragment (THE GREEN FLOOD, Section 6)
// Outputs:
//   colortex0 — gel body color (alpha blend; the see-through base)
//   colortex1 — encoded ripple normal + roughness (a = 1 replaces)
//   colortex2 — absorption color (rgb) + density (a) for composite
//   colortex4 — specular/emissive RGB + refraction mask (a)
// The composite pass then replaces masked pixels with the real
// refracted, absorbed, SSR-lit result (depth-validated).
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/materials.glsl"
#include "/lib/jelly.glsl"
#include "/lib/sky.glsl"

/* RENDERTARGETS: 0,1,2,4 */
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 dataOut;
layout(location = 2) out vec4 absorbOut;
layout(location = 3) out vec4 gelOut;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform float far;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 viewNormal;
in vec3 viewPos;
in vec3 worldPos;
in float matId;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    JcMaterial m = jcMaterialById(matId);
    int id = int(matId + 0.5);

#if VANILLA_MODE != 0
    fragColor = tex;
    dataOut = vec4(jcEncodeNormal(viewNormal), m.roughness, 1.0);
    absorbOut = vec4(0.0);
    gelOut = vec4(0.0);
    return;
#endif

    vec3 viewDir = normalize(-viewPos);
    vec3 lightDir = normalize(shadowLightPosition);

    // ---- animated cellular ripple normals (thick & viscous: slow, large)
    vec3 normal = viewNormal;
    if (m.rippleStrength > 0.0) {
        vec3 wNrm = jcRippleNormal(worldPos.xz, frameTimeCounter, m.rippleScale,
                                   m.rippleStrength * 0.55, 0.55);
        normal = normalize(mat3(gbufferModelView) * wNrm + viewNormal * 0.35);
    }

    float opacity = m.opacity;
    float refrMask = 0.0;
    vec3 absorb = m.absorptionColor;
    float density = m.absorptionDensity;
    vec3 spec = vec3(0.0);

    if (id == 10007) {
        // ================= JELLY LIQUID =================
        // body: deep translucent green seen through the surface
        vec3 body = m.baseColor * (0.35 + 0.65 * clamp(lmcoord.y + 0.1, 0.0, 1.0));
        // internal scattering glow (needs light, thin regions brighter)
        float thin = pow(clamp(dot(normal, viewDir), 0.0, 1.0), 1.5);
        body += m.subsurfaceColor * thin * 0.30;
        fragColor = vec4(body, opacity);

        // sky reflection, Fresnel-weighted (strong at grazing angles)
        vec3 wNrmView = normal;
        vec3 reflDir = reflect(-viewDir, wNrmView);
        vec3 reflWorld = mat3(gbufferModelViewInverse) * reflDir;
        vec3 skyRefl = jcSkyColor(normalize(reflWorld), skyColor, fogColor);
        float fres = jcFresnelF(max(dot(wNrmView, viewDir), 0.0), 0.02) * m.fresnelStrength;
        spec += skyRefl * fres * 1.1;

        // sun glint: sharp and heavy (thick gel)
        float glint = jcGgx(wNrmView, viewDir, lightDir, m.roughness);
        spec += vec3(1.0, 0.98, 0.9) * glint * 2.2 * clamp(lmcoord.y * 1.3, 0.0, 1.0);

        // sparkle
#if SPARKLE_STRENGTH != 0
        spec += vec3(1.0) * jcSparkle(worldPos.xz, 26.0, frameTimeCounter)
                * m.sparkleStrength * (SPARKLE_STRENGTH * 0.01);
#endif
        refrMask = (REFRACTION != 0 ? m.refractionStrength * (REFRACTION_STRENGTH * 0.01) : 0.0);
    } else if (id == 10009) {
        // ================= JELLY LAVA (glowing orange jelly) =========
        float ripple = jcVnoise(worldPos.xz * 2.0 + frameTimeCounter * 0.35);
        vec3 body = m.baseColor * (0.6 + 0.4 * ripple);
        body += m.baseColor * m.emissiveStrength * 1.6;
        fragColor = vec4(body, 1.0);
        // lava emits: strong "spec" that survives refraction skip
        spec = body * 0.8;
        refrMask = 0.0;   // opaque glowing surface, no refraction
    } else {
        // ================= GLASS / ICE / other translucent ===========
        vec3 body = tex.rgb * m.baseColor;
        fragColor = vec4(body, opacity);
        float fres = jcFresnelF(max(dot(normal, viewDir), 0.0), 0.04) * m.fresnelStrength;
        spec += jcSkyColor(normalize(mat3(gbufferModelViewInverse) * reflect(-viewDir, normal)),
                           skyColor, fogColor) * fres * 0.9;
        spec += vec3(1.0) * jcGgx(normal, viewDir, lightDir, m.roughness) * 1.8
                * clamp(lmcoord.y * 1.3, 0.05, 1.0);
        refrMask = (REFRACTION != 0 ? m.refractionStrength * (REFRACTION_STRENGTH * 0.01) : 0.0);
    }

    // distance fog for consistency with terrain
    float dist = length(viewPos);
    float fog = smoothstep(far * 0.65, far * 0.98, dist);
    fragColor.rgb = mix(fragColor.rgb, vec3(0.75, 0.85, 0.95), fog * 0.7);

    dataOut = vec4(jcEncodeNormal(normal), m.roughness, 1.0);
    absorbOut = vec4(absorb, density);
    gelOut = vec4(spec, clamp(refrMask, 0.0, 1.0));
}
