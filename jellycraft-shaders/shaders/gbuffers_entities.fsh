#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_entities fragment
// Reusable entity-material system (Section 7): entityId → material.
// Creeper (10001) & slime (10002): green gel creature — pixel face
// readable inside the gel, internal glow, Fresnel rim, wet clearcoat.
// Others: wet gummy gloss + subsurface. Hurt flash (entityColor)
// preserved exactly. Armor/items on mobs keep their textures.
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
uniform vec4 entityColor;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;
uniform float far;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 viewNormal;
in vec3 viewPos;
in vec3 worldPos;
in float entId;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < 0.05) discard;

    // vanilla hurt/flash overlay preserved BEFORE jelly shading
    tex.rgb = mix(tex.rgb, entityColor.rgb, entityColor.a);

    int id = int(entId + 0.5);
    JcMaterial m = jcEntityMaterial(id);

#if VANILLA_MODE != 0
    vec3 vanillaAmbient = vec3(1.0, 0.76, 0.62) * pow(lmcoord.x, 2.2) * 1.35
                        + vec3(0.82, 0.92, 1.00) * pow(lmcoord.y, 1.6) * 0.95 + 0.035;
    fragColor = vec4(tex.rgb * vanillaAmbient, tex.a);
    dataOut = vec4(jcEncodeNormal(viewNormal), m.roughness, 1.0);
    return;
#endif

    vec3 albedo = tex.rgb;
    vec3 viewDir = normalize(-viewPos);
    vec3 lightDir = normalize(shadowLightPosition);

    if (id == 10001 || id == 10002) {
        // ============ GEL CREATURE (Creeper / Slime) ============
        // "Fake translucency" on opaque geometry (v0.1 scope — no
        // background refraction; see PROGRESS.md limitation note):
        // deep tinted body + pixel texture visible INSIDE the gel,
        // internal glow strongest at thin edges, glossy wet skin.
        float facing = clamp(dot(viewNormal, viewDir), 0.0, 1.0);
        // gel tint deepens toward the middle (thickness proxy)
        vec3 gelBody = albedo * mix(m.baseColor * 0.55, m.baseColor * 1.15,
                                    pow(facing, 1.4));
        // pixel texture stays readable: albedo luminance modulates the gel
        gelBody = mix(gelBody, albedo * 1.6, 0.35 * jcLuminance(albedo));
        // internal glow (needs light to scatter — no free emission)
        float glow = m.subsurfaceStrength * pow(1.0 - facing, 2.0);
        glow *= 0.3 + 0.7 * clamp(lmcoord.y + 0.15, 0.0, 1.0);
        gelBody += m.subsurfaceColor * glow * 0.55;
        // subtle steady inner emissive (fuse-jelly feel)
        gelBody += m.baseColor * m.emissiveStrength * 0.8;

        // glossy wet skin: clearcoat + sun glint + rim
        float coat = m.clearcoat * jcFresnelF(facing, 0.04) * 0.5;
        float glint = jcGgx(viewNormal, viewDir, lightDir, m.roughness) * 2.0
                    * clamp(lmcoord.y * 1.3 + 0.05, 0.0, 1.0);
        vec3 rim = m.subsurfaceColor * pow(1.0 - facing, 3.0) * m.edgeGlow * 0.8;

        vec3 ambient = vec3(1.00, 0.70, 0.45) * pow(lmcoord.x, 2.2) * 1.35
                     + vec3(0.82, 0.92, 1.00) * pow(lmcoord.y, 1.6) * 0.85 + 0.03;
        float wrap = 0.45;
        float diffuse = jcWrapDiffuse(max(dot(viewNormal, lightDir), 0.0), wrap);

        vec3 color = gelBody * (ambient + vec3(0.9, 0.95, 0.85) * diffuse * 0.9);
        color += vec3(1.0, 0.98, 0.92) * glint * (0.02 + m.specular * 0.5);
        color += vec3(0.9, 1.0, 0.95) * coat * clamp(lmcoord.y + 0.25, 0.0, 1.2);
        color += rim;

        float dist = length(viewPos);
        float fog = smoothstep(far * 0.65, far * 0.98, dist);
        color = mix(color, vec3(0.75, 0.85, 0.95), fog * 0.9);

        fragColor = vec4(color, tex.a);
    } else {
        // ============ GENERIC JELLYFIED MOB ============
        albedo = jcWetAlbedo(albedo, m.wetness);
        vec3 color = jcJellyShade(m, albedo, viewNormal, viewDir, lightDir,
                                  lmcoord, worldPos.xz, frameTimeCounter);
        float dist = length(viewPos);
        float fog = smoothstep(far * 0.65, far * 0.98, dist);
        color = mix(color, vec3(0.75, 0.85, 0.95), fog * 0.9);
        fragColor = vec4(color, tex.a);
    }

    dataOut = vec4(jcEncodeNormal(viewNormal), m.roughness, 1.0);
}
