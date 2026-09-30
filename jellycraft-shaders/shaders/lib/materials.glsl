// ================================================================
// JELLYCRAFT — material parameter tables (GLSL mirror of the
// mod-side manifest: assets/jellycraft/materials/materials.json).
//
// INTERFACE CONTRACT (Appendix B):
//   block.properties / entity.properties / item.properties assign
//   numeric IDs; those IDs select a material here. Any change must
//   be made in BOTH this file and materials.json.
//
// Block IDs:    10001 grass  10002 dirt   10003 stone  10004 sand
//               10005 wood   10006 leaves 10007 liquid 10008 ice
//               10009 lava   10010 glass  10011 base(default)
// Entity IDs:   10001 creeper(gel) 10002 slime(gel) 10003 hostile
//               10004 passive 10005 humanoid 10006 ender 10007 item
// Item IDs:     10001 glass tool  10002 glass items  10003 wood tools
// ================================================================

struct JcMaterial {
    vec3  baseColor;
    float roughness;
    float specular;        // F0 scale
    float opacity;
    float transmission;
    float ior;
    float fresnelStrength;
    float subsurfaceStrength;
    vec3  subsurfaceColor;
    vec3  absorptionColor;
    float absorptionDensity;
    float refractionStrength;
    float wetness;
    float clearcoat;
    float clearcoatRoughness;
    float sparkleStrength;
    float edgeGlow;
    float emissiveStrength;
    float jellyAmplitude;  // blocks; multiplied by WOBBLE_STRENGTH
    float rippleStrength;  // liquid surface animation
    float rippleScale;
    float waveAmplitude;   // vertex wave for liquid
};

JcMaterial jcDefaultMaterial() {
    JcMaterial m;
    m.baseColor         = vec3(1.0);
    m.roughness         = 0.35;
    m.specular          = 0.5;
    m.opacity           = 1.0;
    m.transmission      = 0.0;
    m.ior               = 1.33;
    m.fresnelStrength   = 1.0;
    m.subsurfaceStrength= 0.0;
    m.subsurfaceColor   = vec3(1.0);
    m.absorptionColor   = vec3(0.8, 0.6, 0.6);
    m.absorptionDensity = 1.0;
    m.refractionStrength= 0.0;
    m.wetness           = 0.35;
    m.clearcoat         = 0.25;
    m.clearcoatRoughness= 0.15;
    m.sparkleStrength   = 0.0;
    m.edgeGlow          = 0.0;
    m.emissiveStrength  = 0.0;
    m.jellyAmplitude    = 0.002;
    m.rippleStrength    = 0.0;
    m.rippleScale       = 1.0;
    m.waveAmplitude     = 0.0;
    return m;
}

// ---- Jelly firmness levels (Section 1.5.3) -----------------------
// liquid = softest, mob = medium, terrain = firm set, tools = rigid.

JcMaterial jcMaterialById(float id) {
    JcMaterial m = jcDefaultMaterial();
    int i = int(id + 0.5);
    if (i == 10001) { // jelly_grass — lime firm jelly, glossy skin, sparkle
        m.baseColor = vec3(0.42, 0.92, 0.24);
        m.roughness = 0.22; m.specular = 0.62;
        m.transmission = 0.28; m.ior = 1.35; m.fresnelStrength = 1.1;
        m.subsurfaceStrength = 0.5; m.subsurfaceColor = vec3(0.55, 1.0, 0.30);
        m.wetness = 0.8; m.clearcoat = 0.85; m.clearcoatRoughness = 0.06;
        m.sparkleStrength = 0.7; m.edgeGlow = 0.4;
        m.jellyAmplitude = 0.004;
    } else if (i == 10002) { // jelly_dirt — caramel amber jelly, pixels inside
        m.baseColor = vec3(0.78, 0.48, 0.18);
        m.roughness = 0.30; m.wetness = 0.55; m.clearcoat = 0.45;
        m.subsurfaceStrength = 0.25; m.subsurfaceColor = vec3(1.0, 0.62, 0.25);
        m.sparkleStrength = 0.18; m.edgeGlow = 0.2;
        m.jellyAmplitude = 0.002;
    } else if (i == 10003) { // jelly_stone — blue-grey firm jelly
        m.baseColor = vec3(0.58, 0.63, 0.68);
        m.roughness = 0.26; m.wetness = 0.40; m.clearcoat = 0.50;
        m.subsurfaceStrength = 0.12; m.sparkleStrength = 0.30;
        m.jellyAmplitude = 0.0015;
    } else if (i == 10004) { // jelly_sand — pale honey jelly
        m.baseColor = vec3(0.94, 0.82, 0.52);
        m.roughness = 0.28; m.wetness = 0.45;
        m.subsurfaceStrength = 0.30; m.subsurfaceColor = vec3(1.0, 0.85, 0.55);
        m.jellyAmplitude = 0.0025;
    } else if (i == 10005) { // jelly_wood — amber jelly with grain
        m.baseColor = vec3(0.66, 0.42, 0.16);
        m.roughness = 0.32; m.wetness = 0.35; m.clearcoat = 0.40;
        m.subsurfaceStrength = 0.15;
        m.jellyAmplitude = 0.0015;
    } else if (i == 10006) { // jelly_leaves — green gummy, backlit glow
        m.baseColor = vec3(0.30, 0.78, 0.20);
        m.roughness = 0.25; m.specular = 0.62;
        m.transmission = 0.55; m.fresnelStrength = 1.1;
        m.subsurfaceStrength = 0.7; m.subsurfaceColor = vec3(0.55, 1.0, 0.30);
        m.opacity = 0.96; m.sparkleStrength = 0.35; m.edgeGlow = 0.45;
        m.jellyAmplitude = 0.008;
    } else if (i == 10007) { // jelly_liquid — the green flood (softest)
        m.baseColor = vec3(0.36, 0.88, 0.20);
        m.roughness = 0.06; m.specular = 0.85;
        m.opacity = 0.72; m.transmission = 0.90; m.ior = 1.38;
        m.fresnelStrength = 1.25;
        m.subsurfaceStrength = 0.65; m.subsurfaceColor = vec3(0.60, 1.0, 0.35);
        m.absorptionColor = vec3(0.06, 0.32, 0.06); m.absorptionDensity = 1.35;
        m.refractionStrength = 0.22;
        m.wetness = 1.0; m.clearcoat = 1.0; m.clearcoatRoughness = 0.03;
        m.sparkleStrength = 0.25; m.edgeGlow = 0.5;
        m.jellyAmplitude = 0.02; m.rippleStrength = 0.85;
        m.rippleScale = 2.2; m.waveAmplitude = 0.012;
    } else if (i == 10008) { // jelly_ice — clear frosted jelly
        m.baseColor = vec3(0.72, 0.88, 1.0);
        m.roughness = 0.08; m.opacity = 0.80;
        m.transmission = 0.75; m.ior = 1.31; m.refractionStrength = 0.18;
        m.wetness = 0.90; m.clearcoat = 0.90;
        m.absorptionColor = vec3(0.25, 0.45, 0.55); m.absorptionDensity = 0.8;
        m.jellyAmplitude = 0.002;
    } else if (i == 10009) { // jelly_lava — glowing orange jelly
        m.baseColor = vec3(1.0, 0.42, 0.08);
        m.emissiveStrength = 0.85;
        m.absorptionColor = vec3(0.90, 0.25, 0.02); m.absorptionDensity = 2.0;
        m.rippleStrength = 0.5; m.rippleScale = 2.0;
        m.jellyAmplitude = 0.015;
    } else if (i == 10010) { // jelly_glass — clear jelly-glass blocks
        m.baseColor = vec3(0.80, 0.93, 1.0);
        m.roughness = 0.05; m.specular = 0.88;
        m.opacity = 0.45; m.transmission = 0.92; m.ior = 1.50;
        m.fresnelStrength = 1.35; m.refractionStrength = 0.18;
        m.wetness = 0.70; m.clearcoat = 1.0; m.clearcoatRoughness = 0.03;
        m.absorptionColor = vec3(0.10, 0.20, 0.25); m.absorptionDensity = 0.6;
        m.edgeGlow = 0.60;
        m.jellyAmplitude = 0.0008;
    } else if (i == 10011) { // jelly_base default — wet gloss jelly coat
        m.jellyAmplitude = 0.002;
    } else if (i == 10012) { // hand_skin — realistic glossy skin (NOT jelly)
        m.baseColor = vec3(0.92, 0.72, 0.60);
        m.roughness = 0.42; m.specular = 0.35;
        m.wetness = 0.25; m.clearcoat = 0.30; m.clearcoatRoughness = 0.25;
        m.subsurfaceStrength = 0.55; m.subsurfaceColor = vec3(1.0, 0.55, 0.45);
        m.jellyAmplitude = 0.0;
    }
    return m;
}

// Entity materials reuse the same table (entity IDs overlap block IDs
// numerically by design: creeper 10001 shares jelly_grass's gloss
// family but gets gel params below via jcEntityMaterial).
JcMaterial jcEntityMaterial(int entityId) {
    JcMaterial m = jcDefaultMaterial();
    if (entityId == 10001 || entityId == 10002) { // creeper / slime gel
        m.baseColor = vec3(0.36, 0.82, 0.22);
        m.roughness = 0.12; m.specular = 0.75;
        m.opacity = 0.82; m.transmission = 0.60; m.ior = 1.36;
        m.fresnelStrength = 1.30;
        m.subsurfaceStrength = 0.75; m.subsurfaceColor = vec3(0.55, 1.0, 0.30);
        m.absorptionColor = vec3(0.08, 0.30, 0.05); m.absorptionDensity = 1.1;
        m.refractionStrength = 0.10;
        m.wetness = 0.85; m.clearcoat = 0.95; m.clearcoatRoughness = 0.05;
        m.edgeGlow = 0.55; m.emissiveStrength = 0.18;
        m.jellyAmplitude = 0.012;
    } else if (entityId == 10003) { // organic hostile — wet gummy gloss
        m.roughness = 0.30; m.wetness = 0.55; m.clearcoat = 0.45;
        m.subsurfaceStrength = 0.35; m.subsurfaceColor = vec3(1.0, 0.60, 0.40);
        m.edgeGlow = 0.25;
        m.jellyAmplitude = 0.006;
    } else if (entityId == 10004) { // passive — warm gummy
        m.roughness = 0.28; m.wetness = 0.60; m.clearcoat = 0.55;
        m.subsurfaceStrength = 0.45; m.subsurfaceColor = vec3(1.0, 0.65, 0.45);
        m.edgeGlow = 0.30; m.sparkleStrength = 0.10;
        m.jellyAmplitude = 0.007;
    } else if (entityId == 10006) { // ender — deep dark jelly gloss
        m.baseColor = vec3(0.75, 0.62, 0.95);
        m.roughness = 0.15; m.wetness = 0.70; m.clearcoat = 0.80;
        m.edgeGlow = 0.50;
        m.jellyAmplitude = 0.008;
    } else { // humanoid & default
        m.roughness = 0.32; m.wetness = 0.45; m.clearcoat = 0.40;
        m.subsurfaceStrength = 0.30; m.subsurfaceColor = vec3(1.0, 0.58, 0.45);
        m.jellyAmplitude = 0.005;
    }
    return m;
}

JcMaterial jcItemMaterial(int itemId) {
    JcMaterial m = jcDefaultMaterial();
    if (itemId == 10001 || itemId == 10002) { // jelly_glass_tool
        m.baseColor = vec3(0.78, 0.92, 1.0);
        m.roughness = 0.04; m.specular = 0.90;
        m.opacity = 0.55; m.transmission = 0.92; m.ior = 1.50;
        m.fresnelStrength = 1.35;
        m.refractionStrength = 0.30;
        m.wetness = 0.70; m.clearcoat = 1.0; m.clearcoatRoughness = 0.02;
        m.edgeGlow = 0.65; m.sparkleStrength = 0.35;
        m.absorptionColor = vec3(0.12, 0.18, 0.28); m.absorptionDensity = 0.5;
        m.jellyAmplitude = 0.0008;
    } else if (itemId == 10003) { // wooden tools — amber jelly
        m.baseColor = vec3(0.66, 0.42, 0.16);
        m.roughness = 0.30; m.wetness = 0.40; m.clearcoat = 0.45;
        m.subsurfaceStrength = 0.15;
        m.jellyAmplitude = 0.001;
    } else { // generic held things — light jelly gloss
        m.roughness = 0.30; m.wetness = 0.45; m.clearcoat = 0.40;
        m.jellyAmplitude = 0.001;
    }
    return m;
}
