// ================================================================
// JELLYCRAFT — common math helpers (stage-agnostic, no uniforms here)
// ================================================================

#define JC_PI 3.14159265359

float jcLuminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 jcSaturation(vec3 c, float s) {
    float l = jcLuminance(c);
    return mix(vec3(l), c, s);
}

// ---- Hash / noise (no textures needed; deterministic) ------------
float jcHash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float jcHash13(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 jcHash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float jcVnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = jcHash12(i);
    float b = jcHash12(i + vec2(1.0, 0.0));
    float c = jcHash12(i + vec2(0.0, 1.0));
    float d = jcHash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float jcVnoise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = jcHash13(i);
    float n100 = jcHash13(i + vec3(1, 0, 0));
    float n010 = jcHash13(i + vec3(0, 1, 0));
    float n110 = jcHash13(i + vec3(1, 1, 0));
    float n001 = jcHash13(i + vec3(0, 0, 1));
    float n101 = jcHash13(i + vec3(1, 0, 1));
    float n011 = jcHash13(i + vec3(0, 1, 1));
    float n111 = jcHash13(i + vec3(1, 1, 1));
    return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
               mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

float jcFbm(vec2 p, int octaves) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < octaves; i++) {
        v += a * jcVnoise(p);
        p = p * 2.03 + vec2(11.7, 5.3);
        a *= 0.5;
    }
    return v;
}

// ---- Normal encoding (colortex1, RGBA16) ------------------------
vec2 jcEncodeNormal(vec3 n) {
    return n.xy * 0.5 + 0.5;
}

vec3 jcDecodeNormal(vec2 enc) {
    return normalize(vec3(enc * 2.0 - 1.0, 0.0) + vec3(0.0, 0.0, 1.0));
    // Only used for view-space normals where z > 0; kept simple & lossless enough for RGBA16.
}

// ---- Tonemap (ACES approximation, Narkowicz) --------------------
vec3 jcAces(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

// ---- Fresnel (Schlick) ------------------------------------------
vec3 jcFresnel(float cosTheta, vec3 f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float jcFresnelF(float cosTheta, float f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

// ---- Beer-Lambert absorption through jelly ----------------------
vec3 jcBeerLambert(vec3 absorptionColor, float density, float thicknessBlocks) {
    // absorptionColor in [0,1]: per-channel transmittance per unit at reference density.
    vec3 sigma = (1.0 - absorptionColor) * density;
    return exp(-sigma * max(thicknessBlocks, 0.0));
}

// ---- GGX specular (simplified) ----------------------------------
float jcGgx(vec3 n, vec3 v, vec3 l, float roughness) {
    float a = max(roughness * roughness, 1e-4);
    vec3 h = normalize(v + l);
    float nh = max(dot(n, h), 0.0);
    float d = nh * nh * (a * a - 1.0) + 1.0;
    d = (a * a) / (JC_PI * d * d);
    float vh = max(dot(v, h), 0.0);
    return d * vh * (roughness < 0.35 ? 1.0 : 0.9); // cheap visibility proxy
}
