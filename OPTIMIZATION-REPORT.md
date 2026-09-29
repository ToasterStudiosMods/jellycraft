# JELLYCRAFT — Optimization Report v0.1.0

## Honest status

The build environment has **no GPU/display** — no baseline FPS and no per-pass GPU
timings could be measured. This report therefore documents (a) the performance
**design** — every optimization that is BUILT IN, (b) the measurement **protocol**
to run on real hardware, and (c) the budget targets each preset is engineered to meet.
Measured numbers will be appended in v0.2 by whoever runs the protocol.

## Performance budget targets (per master spec Section 15.1)

| Preset | Frame-time overhead over baseline (vanilla+Sodium+Iris, pack off) | Engineered via |
|---|---|---|
| Low | ≤ 10% | no SSR, no shadow map, no caustics; refraction = 1 composite fetch chain |
| Medium | ≤ 25% | as Low + full sparkle/subsurface/wobble at tuned strength |
| High | ≤ 50% | + 2048px soft shadows (3×3 PCF), SSR 16 steps, caustics |
| Ultra | uncapped, justified per pass | SSR 32 steps, everything on |

## Optimizations that are already in the build (shader side)

1. **Preset-gated code paths, not runtime branches.** `#define` option tiers are
   rewritten by Iris at shader-compile time — Low/Medium genuinely compile simpler
   shaders (no SSR loop, no shadow sampling, no caustic noise) per spec §15.2.
2. **No fullscreen passes beyond necessity.** Whole pipeline: 1 deferred copy
   (colortex0→colortex3), 1 composite (refraction+SSR+caustics+underwater), 1 final
   (tonemap+bloom+grade). Bloom is an 8-tap ring inside final — no half-res ping-pong
   chain, no extra buffers, no readback stalls.
3. **Refraction replaces, never accumulates.** Gel pixels are shaded once; the
   composite replaces them using a single texture fetch chain (backup + absorption +
   stored spec), with a depth-validation branch that falls back to the undistorted
   fetch — constant cost, no branching divergence across the water quad.
4. **SSR is coarse-to-fine.** Step length grows 1.18× per step; steps capped by
   preset (8/16/32); sky fallback is a closed-form gradient, never loop work.
   SSR only runs on pixels whose Fresnel weight > 0.08 (grazing angles), which is a
   minority of the liquid screen area.
5. **Distance gates on everything expensive.** Wobble displacement fades 64→40 m;
   fog handles the rest. Sparkle is a 2×2 cell hash (4 hash evals), not 3×3.
6. **No texture bandwidth waste.** All noise is procedural hash-based (no noise
   textures to sample); material data comes from numeric IDs (mc_Entity/entityId/
   itemId), never per-fragment lookups. Buffer formats: RGBA16F only where HDR is
   needed (0,3,4), RGBA16 for normals, so bandwidth stays low.
7. **Overdraw control.** Water writes gel data in the same pass as its color (no
   extra geometry pass); translucents are depth-rejected normally by the fixed
   pipeline; lava skips the refraction mask entirely.
8. **Fixed loop bounds everywhere.** All loops (SSR, PCF, sparkle, bloom) are
   compile-time-bounded — no dynamic iteration counts, GPU-friendly unrolling.

## Optimizations in the build (mod side, Java)

1. **Zero mixins** → zero per-frame injected overhead in chunk rendering (Sodium
   path completely untouched).
2. **Material lookups are map-free at runtime.** The material registry loads JSON on
   resource reload only (off the hot path); no per-frame parsing, no reflection,
   no allocation in render paths.
3. **One-step installer does I/O once** (hash-marked), never per-tick; the client
   tick handler is two `if`s + a keybind poll.
4. **Config is a plain Gson file**, cached in a static instance; saves only on change.

## Measurement protocol (run on real hardware, then append results)

1. **Baseline:** vanilla 1.21.11 + Fabric + Sodium 0.8.14 + Iris 1.10.8, pack disabled.
   Fixed seed, fixed camera positions (the QA scenes 1–14), render distance 12, 1080p.
   Record avg FPS, 1% lows, frame time (F3 + Iris's F3 shader debug or Spark).
2. **Pack on, per preset:** repeat for Low/Medium/High/Ultra. Compute overhead %.
3. **Per-pass cost:** Iris can show shader pass timings with its debug overlay; or
   RenderDoc/Nsight capture: deferred / composite / final / gbuffers_water /
   gbuffers_terrain. Fill the table below.
4. **Stability:** 5-minute walk at High — no hitches (chunk load), no VRAM growth
   across dimension change + resource reload + preset switch.

### Per-pass cost table (TO MEASURE)

| Pass | GPU ms (Low) | GPU ms (Med) | GPU ms (High) | GPU ms (Ultra) | Notes |
|---|---|---|---|---|---|
| gbuffers_terrain | | | | | dominant pass; adds GGX+sparkle vs vanilla |
| gbuffers_water | | | | | ripple normals + gel outputs |
| deferred (copy) | | | | | ~1 fullscreen copy |
| composite | | | | | refraction; +SSR on High/Ultra |
| final | | | | | bloom ring + ACES |
| shadow | — | — | | | High+ only |

## Recommended hardware tiers

- **Low:** Intel Iris Xe / old iGPU laptops — expect comfortable 60 fps at 8–12 chunks.
- **Medium:** GTX 1050 / RX 560 class and up.
- **High:** GTX 1660 / RX 5600 class and up.
- **Ultra:** RTX 3060 / RX 6700 class and up (SSR 32 + full shadows).

## Auto-quality governor

Not enabled in v0.1 (off by default per spec). The option framework (per-effect
toggles + presets) is the manual equivalent; a governor that steps effects down in
priority order (caustics → SSAO res → SSR steps → refraction quality) is roadmap
and requires only shader-side defines plus a small mod-side ticker — no architectural
change needed.
