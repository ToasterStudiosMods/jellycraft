#version 330 compatibility
// ================================================================
// JELLYCRAFT — composite fragment — THE GEL PASS (Sections 6/9/12)
//  1. Refraction: masked gel pixels (liquid, glass, glass tool)
//     sample the opaque backup (colortex3) with normal-based UV
//     distortion, depth-validated so foreground objects never
//     smear into the gel, then Beer-Lambert absorption by actual
//     thickness (opaque depth − surface depth).
//  2. SSR (SSR>0): screen-space reflections of nearby terrain on
//     the liquid, sky fallback on miss (never black).
//  3. Caustics (CAUSTICS>0): caustic-like shimmer through the gel.
//  4. Underwater camera: green absorption + gentle screen ripple.
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/sky.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

uniform sampler2D colortex0;   // current color (gel blended in)
uniform sampler2D colortex1;   // encoded normal + roughness
uniform sampler2D colortex2;   // absorption color (rgb) + density (a)
uniform sampler2D colortex3;   // opaque scene backup (refraction src)
uniform sampler2D colortex4;   // spec RGB + refraction mask (a)
uniform sampler2D depthtex0;   // depth incl. translucent + hand
uniform sampler2D depthtex1;   // depth without translucents (opaque)

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float frameTimeCounter;
uniform float near;
uniform float far;
uniform int isEyeInWater;

in vec2 texcoord;

float jcLinearize(float depth) {
    return (2.0 * near * far) / (far + near - (depth * 2.0 - 1.0) * (far - near));
}

vec3 jcViewPosAt(vec2 uv, float depth) {
    vec4 ndc = vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 vp = gbufferProjectionInverse * ndc;
    return vp.xyz / vp.w;
}

void main() {
    vec4 color = texture(colortex0, texcoord);
    vec4 gelData = texture(colortex4, texcoord);
    float mask = gelData.a;

    // ---------------- underwater camera (Section 6) ----------------
    if (isEyeInWater == 1) {
        vec2 ripple = vec2(jcVnoise(texcoord * vec2(24.0, 14.0) + frameTimeCounter * 0.15),
                           jcVnoise(texcoord * vec2(24.0, 14.0) - frameTimeCounter * 0.12));
        vec2 duv = (ripple - 0.5) * 0.010;
        vec3 under = texture(colortex0, clamp(texcoord + duv, 0.001, 0.999)).rgb;
        float depth = jcLinearize(texture(depthtex0, texcoord).r);
        vec3 absorb = jcBeerLambert(vec3(0.06, 0.32, 0.06), 0.9, depth * 1.1);
        under *= absorb;
        under = mix(under, vec3(0.02, 0.18, 0.05), smoothstep(12.0, 42.0, depth));
        fragColor = vec4(under, 1.0);
        return;
    }

    if (mask > 0.04) {
        // ---------------- REFRACTION through the gel ----------------
        vec2 encN = texture(colortex1, texcoord).rg;
        vec3 normal = normalize(vec3(encN * 2.0 - 1.0, 0.35));
        float surfaceDepth = texture(depthtex0, texcoord).r;
        float surfLinear = jcLinearize(surfaceDepth);

        float refrStrength = mask * 0.55;
        vec2 duv = normal.xy * refrStrength / vec2(1.0, 0.75);   // aspect-ish compensation
        vec2 refrUv = clamp(texcoord + duv, 0.001, 0.999);

        // depth validation: the sample must be BEHIND the gel surface
        float opaqueAtRefr = texture(depthtex1, refrUv).r;
        float refrLinear = jcLinearize(opaqueAtRefr);
        if (refrLinear < surfLinear - 1.0) {
            refrUv = texcoord;   // foreground object behind the sample — fall back
            refrLinear = jcLinearize(texture(depthtex1, refrUv).r);
        }

        vec3 transmitted = texture(colortex3, refrUv).rgb;

        // Beer-Lambert absorption by real thickness
        vec4 absorbData = texture(colortex2, texcoord);
        float thickness = max(refrLinear - surfLinear, 0.15);
        vec3 absorb = jcBeerLambert(absorbData.rgb, absorbData.a, thickness);

        // Keep transparent gel neutral/aqua.  The old lime-to-emerald grade
        // painted the entire world yellow-green instead of reading as clear jelly.
        vec3 shallowTint = vec3(0.66, 0.94, 0.86);
        float depthMix = clamp(thickness / 4.0, 0.0, 1.0);
        vec3 gelTint = mix(shallowTint, vec3(0.12, 0.40, 0.32), depthMix);
        transmitted = transmitted * mix(vec3(1.0), gelTint, 0.18) * absorb;

#if CAUSTICS != 0
        // caustic-like shimmer seen through the gel (Ref 3 patches)
        vec3 surfWorld = (gbufferModelViewInverse * vec4(jcViewPosAt(texcoord, surfaceDepth), 1.0)).xyz;
        float caustic = pow(jcVnoise(surfWorld.xz * 3.1 + frameTimeCounter * 0.35), 3.0)
                      + pow(jcVnoise(surfWorld.xz * 5.7 - frameTimeCounter * 0.28), 4.0);
        transmitted *= 1.0 + caustic * 0.55;
#endif

        vec3 result = transmitted + gelData.rgb;

        // ---------------- SSR on the liquid (SSR>0) ----------------
#if SSR != 0
        // reflection weight grows at grazing angles (Fresnel)
        float fres = jcFresnelF(clamp(normal.z, 0.0, 1.0), 0.02);
        if (fres > 0.08) {
            vec3 vp = jcViewPosAt(texcoord, surfaceDepth);
            vec3 viewDir = normalize(vp);
            vec3 refl = reflect(viewDir, normal);
            vec3 rayPos = vp + refl * (near + 0.5);
            vec3 hitColor = vec3(0.0);
            bool hit = false;
            float stepLen = 0.35;
            for (int i = 0; i < SSR_STEPS; i++) {
                rayPos += refl * stepLen;
                stepLen *= 1.18;                       // coarse-to-fine growth
                vec4 clip = gbufferProjection * vec4(rayPos, 1.0);
                vec2 suv = clip.xy / clip.w * 0.5 + 0.5;
                if (clamp(suv, 0.0, 1.0) != suv) break;
                float sceneDepth = jcLinearize(texture(depthtex1, suv).r);
                float rayDepth = -rayPos.z;
                if (rayDepth > sceneDepth + 0.35 && rayDepth < sceneDepth + 3.0) {
                    hitColor = texture(colortex3, suv).rgb;
                    hit = true;
                    break;
                }
            }
            if (!hit) {
                // sky fallback — never a black hole
                vec3 reflWorld = mat3(gbufferModelViewInverse) * refl;
                hitColor = jcSkyColor(normalize(reflWorld), skyColor, fogColor);
            }
            result += hitColor * fres * 0.85;
        }
#endif
        color.rgb = result;
    }

    fragColor = color;
}
