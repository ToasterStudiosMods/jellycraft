// ================================================================
// JELLYCRAFT — shader options (parsed by the Iris options screen).
// These #define lines are REWRITTEN by Iris when the user changes
// settings or profiles; do not wrap them in #ifndef guards.
// Quality tiers compile genuinely different shaders (Section 15.2).
// ================================================================

#define VANILLA_MODE 0 // [0 1]
#define WOBBLE 1 // [0 1]
#define WOBBLE_STRENGTH 100 // [0 25 50 75 100 125 150 200]
#define PLAYER_BEND 1 // [0 1]
#define PLAYER_BEND_STRENGTH 100 // [0 25 50 75 100 125 150 200]
#define BLOCK_TRANSLUCENCY 6 // [0 3 6 10 15]
#define SPARKLE_STRENGTH 100 // [0 25 50 75 100 125 150 200]
#define SUBSURFACE 100 // [0 25 50 75 100 125 150 200]
#define WETNESS 100 // [0 25 50 75 100 125 150 200]
#define REFRACTION 1 // [0 1]
#define REFRACTION_STRENGTH 100 // [0 25 50 75 100 125 150 200]
#define SSR 1 // [0 1]
#define SSR_STEPS 16 // [8 12 16 24 32]
#define SHADOWS 1 // [0 1]
#define CAUSTICS 1 // [0 1]
#define BLOOM 1 // [0 1]
#define BLOOM_STRENGTH 100 // [25 50 75 100 125 150]
#define EXPOSURE 100 // [75 90 100 110 125 150]
#define SATURATION 100 // [80 90 100 110 120 130]
