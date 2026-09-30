// ================================================================
// JELLYCRAFT — jelly behaviour functions (the "Jelly Bible" in GLSL)
//  - world-space coherent wobble (no cracks between blocks)
//  - animated cellular ripple normals for the liquid
//  - sparkle glints, edge glow, subsurface wrap
//  - lightmap-driven jelly lighting core shared by all gbuffers
// ================================================================

// ---- World-space coherent jelly wobble (Appendix C) -------------
// Displacement is a CONTINUOUS function of world position, so
// vertices shared between neighbouring blocks move identically and
// no cracks can open. Impulse-driven damped springs (landing, break)
// need event uniforms that Iris cannot feed; v0.1 ships the ambient
// idle sway only (honest scope; see PROGRESS.md).
vec3 jcWobble(vec3 worldPos, vec3 worldNormal, float amplitude, float stiffness, float time) {
    float w = 1.2 + stiffness * 2.2;                 // jelly frequency scale
    float sway = sin(worldPos.x * 1.35 + time * w)
               + sin(worldPos.z * 1.15 + time * w * 0.83 + worldPos.y * 0.9)
               + 0.5 * sin(worldPos.y * 2.1 - time * w * 1.27);
    sway *= 0.4;                                     // ~[-1, 1]
    return worldNormal * amplitude * sway;
}

// ---- Player pressure field ---------------------------------------
// A shader cannot receive walking events, but it does receive every vertex in
// player-relative coordinates.  Keeping this field in that space makes the
// depression travel with the player: terrain bows away while you walk through
// it, then the small travelling rings make it settle like a dense gel.  This
// intentionally does not use the face normal, so a shared terrain vertex gets
// precisely the same displacement from every adjacent block face (no seams).
vec3 jcPlayerBend(vec3 playerRelativePos, float time, float strength) {
    vec2 horizontal = playerRelativePos.xz;
    float radius = length(horizontal);
    float nearField = 1.0 - smoothstep(0.55, 6.0, radius);
    float groundBand = smoothstep(-2.4, -0.15, playerRelativePos.y)
                     * (1.0 - smoothstep(1.15, 3.8, playerRelativePos.y));
    float weight = nearField * groundBand * strength;
    vec3 radial = vec3(horizontal.x, 0.0, horizontal.y) / max(radius, 0.001);
    float settle = 0.76 + 0.24 * sin(radius * 5.4 - time * 4.2);
    // Outward shear plus a shallow downward bowl; 0.14 blocks at 100% is
    // visible without turning a walkable voxel world into liquid spaghetti.
    return radial * (0.115 * weight * settle) + vec3(0.0, -0.055 * weight, 0.0);
}

// ---- Liquid surface: animated cellular ripple normals (Ref 4) ---
// Two noise layers scrolled in different directions + a slow large
// swell layer (Ref 3). Thick and viscous: low frequency, slow speed.
vec3 jcRippleNormal(vec2 worldXZ, float time, float scale, float strength, float speed) {
    vec2 p = worldXZ * scale;
    float t = time * speed;
    // cellular-ish: sharpen value noise toward cells
    float n1 = jcVnoise(p * 0.9 + vec2(t * 0.55, -t * 0.35));
    float n2 = jcVnoise(p * 1.7 - vec2(t * 0.30, t * 0.47));
    float swell = jcVnoise(p * 0.28 + vec2(-t * 0.12, t * 0.09));
    float h = (0.55 * n1 + 0.35 * n2 + 0.35 * swell) * strength;
    // finite-difference normal (eps kept >= a texel-ish to stay smooth)
    float e = 0.28;
    float hx = (jcVnoise((p + vec2(e, 0.0)) * 0.9 + vec2(t * 0.55, -t * 0.35)) * 0.55
              + jcVnoise((p + vec2(e, 0.0)) * 1.7 - vec2(t * 0.30, t * 0.47)) * 0.35
              + jcVnoise((p + vec2(e, 0.0)) * 0.28 + vec2(-t * 0.12, t * 0.09)) * 0.35) * strength;
    float hz = (jcVnoise((p + vec2(0.0, e)) * 0.9 + vec2(t * 0.55, -t * 0.35)) * 0.55
              + jcVnoise((p + vec2(0.0, e)) * 1.7 - vec2(t * 0.30, t * 0.47)) * 0.35
              + jcVnoise((p + vec2(0.0, e)) * 0.28 + vec2(-t * 0.12, t * 0.09)) * 0.35) * strength;
    return normalize(vec3(-(hx - h) / e, 1.0, -(hz - h) / e));
}

// ---- Sparkle glints (Refs 2/4) -----------------------------------
// Hash-grid twinkles over time; gated by sparkle strength.
float jcSparkle(vec2 worldXZorUV, float scale, float time) {
    vec2 g = worldXZorUV * scale;
    vec2 cell = floor(g);
    vec2 f = fract(g);
    float best = 0.0;
    // only own cell + right/down neighbours: cheap, no loop over 9
    for (int j = 0; j < 2; j++) {
        for (int i = 0; i < 2; i++) {
            vec2 off = vec2(float(i), float(j));
            vec2 jitter = jcHash22(cell + off);
            vec2 pos = off + jitter;                       // glint position in cell
            float twinkle = 0.55 + 0.45 * sin(time * (2.0 + jitter.x * 4.0) + jitter.y * 6.28);
            float d = length(f - pos + (jitter - 0.5) * 0.4);
            best = max(best, twinkle * smoothstep(0.16, 0.0, d));
        }
    }
    return best;
}

// ---- Subsurface wrap (fake but stable) ---------------------------
// Wrapped diffuse: light bleeds around edges, thin parts glow.
float jcWrapDiffuse(float nl, float wrap) {
    return clamp((nl + wrap) / (1.0 + wrap), 0.0, 1.0);
}

// ---- Jelly lighting core -----------------------------------------
// Shared by terrain/entities/hand: lightmap-driven ambient + sun
// specular + clearcoat + edge glow + sparkle. Returns lit color.
//   albedo    texture albedo (already tinted)
//   mat       material params
//   normal    surface normal (world or view consistent with lightDir)
//   viewDir   direction from surface to eye (same space as normal)
//   lightDir  direction from surface to sun (same space)
//   lm        lightmap coords [0,1]
//   worldXZ   for sparkle hashing
//   time      frameTimeCounter
vec3 jcJellyShade(JcMaterial mat, vec3 albedo, vec3 normal, vec3 viewDir, vec3 lightDir,
                  vec2 lm, vec2 worldXZ, float time) {
    // --- vanilla-faithful ambient from lightmap (keeps caves readable)
    vec3 blockLight = vec3(1.00, 0.70, 0.45) * pow(lm.x, 2.2) * 1.35;
    vec3 skyLight   = vec3(0.82, 0.92, 1.00) * pow(lm.y, 1.6) * 0.85;
    vec3 ambient    = blockLight + skyLight + vec3(0.03);

    float nl = dot(normal, lightDir);
    float wrap = clamp(mat.subsurfaceStrength * 0.5, 0.0, 0.9);
    float diffuse = jcWrapDiffuse(max(nl, 0.0), wrap);

    // --- subsurface: thin/edges glow with the material's inner color
    float sss = mat.subsurfaceStrength * pow(clamp(1.0 - abs(dot(normal, viewDir)), 0.0, 1.0), 2.0);
    sss *= 0.35 + 0.65 * clamp(lm.y + 0.15, 0.0, 1.0);   // needs light to scatter
    vec3 subsurface = mat.subsurfaceColor * sss * 0.5;

    // --- specular: wet GGX sun glint
    float f0 = clamp(mat.specular * 0.5 + 0.02, 0.02, 0.9);
    float gloss = mix(1.0, 0.15, mat.roughness);
    float wetnessScale = mix(1.0, 1.6, mat.wetness * (WETNESS * 0.01));
    float spec = jcGgx(normal, viewDir, lightDir, mat.roughness) * gloss * wetnessScale;
    spec *= clamp(lm.y * 1.2, 0.05, 1.0) * max(nl * 0.5 + 0.5, 0.0);

    // --- clearcoat: broad soft sheen (the gel skin)
    float coat = mat.clearcoat * jcFresnelF(max(dot(normal, viewDir), 0.0), 0.04);
    coat *= 1.0 - mat.clearcoatRoughness * 0.8;

    // --- edge / rim glow
    float rim = mat.edgeGlow * pow(clamp(1.0 - abs(dot(normal, viewDir)), 0.0, 1.0), 3.0);

    // --- sparkle
#if SPARKLE_STRENGTH != 0
    float sparkle = 0.0;
    if (mat.sparkleStrength > 0.0) {
        sparkle = jcSparkle(worldXZ, 22.0, time) * mat.sparkleStrength * (SPARKLE_STRENGTH * 0.01);
        sparkle *= clamp(lm.y * 1.4, 0.0, 1.0);
    }
#else
    float sparkle = 0.0;
#endif

    // --- combine (keep pixels crisp: no albedo blur, only lighting on top)
    vec3 color = albedo * mat.baseColor * (ambient + vec3(0.9, 0.95, 0.85) * diffuse * 0.9);
    color += subsurface * (SUBSURFACE * 0.01);
    color += vec3(1.0, 0.98, 0.92) * (spec + sparkle) * f0 * 1.6;
    color += vec3(0.9, 1.0, 0.95) * coat * 0.35 * clamp(lm.y + 0.25, 0.0, 1.2);
    color += mat.subsurfaceColor * rim * 0.6;
    return color;
}

// ---- Wet darkening (dirt must not read as "dirt + shine filter") --
vec3 jcWetAlbedo(vec3 albedo, float wetness) {
    float w = clamp(wetness * (WETNESS * 0.01), 0.0, 1.0);
    return albedo * mix(1.0, 0.72, w);   // darker, richer when wet
}
