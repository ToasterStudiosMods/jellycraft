#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_terrain fragment
// Jelly materials by mc_Entity id: wet albedo, per-texel normals,
// sparkle glints, subsurface wrap, clearcoat skin, edge glow,
// soft shadows (SHADOWS), distance fog.
// colortex0: lit color · colortex1: encoded normal + roughness
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

#if SHADOWS != 0
uniform sampler2D shadowtex0;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
#endif

uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float far;
uniform float rainStrength;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 viewNormal;
in vec3 viewPos;
in vec3 worldPos;
in float matId;

#if SHADOWS != 0
float jcShadowFactor(vec3 vPos, float NoL) {
    vec3 shadowView = (shadowModelView * vec4(vPos, 1.0)).xyz;
    vec4 sc = shadowProjection * vec4(shadowView, 1.0);
    sc.xyz /= sc.w;
    sc.xyz = sc.xyz * 0.5 + 0.5;
    if (clamp(sc.xyz, 0.0, 1.0) != sc.xyz) return 1.0;   // outside shadow map
    float bias = 0.0008 + (1.0 - NoL) * 0.0012;
    float shadow = 0.0;
    float texel = 1.0 / 2048.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float d = texture(shadowtex0, sc.xy + vec2(x, y) * texel).r;
            shadow += step(sc.z - bias, d);
        }
    }
    shadow /= 9.0;
    return mix(shadow, 1.0, rainStrength * 0.8);          // softer shadows in rain
}
#endif

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < 0.1) discard;

    JcMaterial m = jcMaterialById(matId);
    vec3 albedo = tex.rgb;

#if VANILLA_MODE != 0
    vec3 vanillaAmbient = vec3(1.0, 0.76, 0.62) * pow(lmcoord.x, 2.2) * 1.35
                        + vec3(0.82, 0.92, 1.00) * pow(lmcoord.y, 1.6) * 0.95 + 0.035;
    fragColor = vec4(albedo * vanillaAmbient, tex.a);
    dataOut = vec4(jcEncodeNormal(viewNormal), m.roughness, 1.0);
    return;
#endif

    // ---- wet response: darker albedo + glossier (not a shine filter)
    albedo = jcWetAlbedo(albedo, m.wetness);

    // ---- per-texel normal variation (pixel grid stays crisp, Section 5.5)
    float lum = jcLuminance(albedo);
    float dxL = dFdx(lum);
    float dyL = dFdy(lum);
    float nStrength = 0.22 + 0.18 * (1.0 - m.roughness);
    vec3 normal = normalize(viewNormal + vec3(dxL, dyL, 0.0) * -nStrength);

    vec3 viewDir = normalize(-viewPos);
    vec3 lightDir = normalize(shadowLightPosition);
    float NoL = dot(normal, lightDir);

#if SHADOWS != 0
    float shadow = jcShadowFactor(viewPos, NoL);
#else
    float shadow = 1.0;
#endif

    vec3 color = jcJellyShade(m, albedo, normal, viewDir, lightDir, lmcoord, worldPos.xz, frameTimeCounter);
    color *= mix(0.35, 1.0, shadow);

    // ---- internal emissive (lava etc.)
    if (m.emissiveStrength > 0.0) {
        color += m.baseColor * m.emissiveStrength * 1.4;
    }

    // ---- light distance fog, tinted to sky, saturation-preserving
    float dist = length(viewPos);
    float fog = smoothstep(far * 0.65, far * 0.98, dist);
    color = mix(color, vec3(0.75, 0.85, 0.95), fog * 0.9);

    // A thin 6% transmission layer makes every solid block read as set jelly.
    // The terrain pass has alpha blending enabled in shaders.properties; retain
    // texture cutout alpha so leaves, grass and panes still cut out correctly.
    float jellyAlpha = tex.a * (1.0 - BLOCK_TRANSLUCENCY * 0.01);
    fragColor = vec4(color, jellyAlpha);
    dataOut = vec4(jcEncodeNormal(normal), m.roughness, 1.0);
}
