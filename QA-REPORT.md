# JELLYCRAFT — QA Report v0.1.0

Honesty first: this report separates **VERIFIED** (proven by tooling during the build)
from **UNTESTED** (needs the real game, which the build environment cannot launch —
no GPU/display). Nothing in the UNTESTED list is claimed to work.

## VERIFIED during build (evidence)

| # | Check | Evidence |
|---|---|---|
| 1 | Mod compiles against the real Minecraft 1.21.11 mapped jar | `gradle build` → BUILD SUCCESSFUL (Loom 1.18.2, Mojmap, JDK 25 toolchain / Java 21 target) |
| 2 | 1.21.11 API names used are real, not hallucinated | `javap` on the mapped jar: `net.minecraft.resources.Identifier.fromNamespaceAndPath` ✓, `net.minecraft.server.packs.PackType.CLIENT_RESOURCES` ✓, `KeyMapping(String, int, KeyMapping.Category)` + `KeyMapping.Category.register(Identifier)` ✓, `Screen(Component)` ✓, `Button.builder(...).bounds(...).build()` ✓, `GuiGraphics.drawCenteredString(Font, Component, int, int, int)` ✓, `SimplePreparableReloadListener.prepare/apply` ✓, `ResourceProvider.getResource(Identifier)` ✓, `Resource.openAsReader()` ✓ |
| 3 | Fabric API mechanisms are real | javap on remapped FAPI 0.141.6: `ResourceLoader.registerBuiltinPack(Identifier, ModContainer, PackActivationType)` ✓ (`PackActivationType.DEFAULT_ENABLED` ✓), `ResourceManagerHelper.get(PackType)` ✓, `KeyBindingHelper.registerKeyBinding` ✓, `ClientLifecycleEvents.CLIENT_STARTED` ✓, `ClientTickEvents.END_CLIENT_TICK` ✓, `IdentifiableResourceReloadListener.getFabricId()` ✓ |
| 4 | Iris API is real | javap on Iris 1.10.8 jar: `IrisApi.getInstance/isShaderPackInUse/getConfig` ✓, `Iris.getIrisConfig/getShaderpacksDirectory/reload` ✓, `IrisConfig.setShaderPackName/setShadersEnabled/save` ✓. Iris is compileOnly — never crashes when absent (all calls behind classloader guard `IrisCompat.IrisBridge`) |
| 5 | Mod jar layout | jar listing shows `fabric.mod.json` (version expanded), `resourcepacks/jelly/**` (builtin art pack), `assets/jellycraft/shaderpacks/jellycraft-shaders.zip` (42,572 B), classes, lang, icon |
| 6 | Shader pack zip layout | 48 files, `shaders/` at archive ROOT (Iris requirement), no wrapper folder |
| 7 | Resource pack zip layout | `pack.mcmeta` at root, pack_format 69 with supported_formats [46, 999] |
| 8 | Materials manifest | valid JSON, 15 materials, inheritance + LOW/MEDIUM/HIGH/ULTRA overrides + block/entity/item assignment tables; loader code compiles and clamps bad data |
| 9 | Mod has ZERO mixins | no mixin config anywhere — the biggest crash-risk class for Sodium compat is absent by design |
| 10 | .mrpack references real CDN files | URLs + sha1/sha512 fetched live from Modrinth API for fabric-api 0.141.6, sodium 0.8.14, iris 1.10.8 |

## UNTESTED — requires launching the real game (owner checklist, ~15 min)

1. **Shader pack compiles in Iris.** GLSL is hand-checked against Iris/OptiFine
   conventions (`#version 330 compatibility`, `RENDERTARGETS` comments, `gtexture`,
   `mc_Entity`/`entityId`/`itemId`, `deferred` between opaque and translucent) but
   **no GLSL validator or GPU existed in the build environment**. If Iris shows a
   shader-compile error, send the log line — every program is boilerplate + shared
   lib includes, so fixes are one-file.
2. First-run auto-install/auto-enable of the shader pack (code paths verified by
   javap; behavior not run).
3. Visual quality of every material (colors/gloss/sparkle tuned from the spec text,
   not from screenshots — **the four reference images never arrived in the build
   environment**, so all visual constants are LOW-CONFIDENCE and marked as such).
4. Performance budgets per preset (see OPTIMIZATION-REPORT.md).
5. The jelly-glass pickaxe item model renders in hand/GUI/drops.
6. Wobble/ripple motion feel (comfort default is conservative).
7. Underwater view, Nether/End, rain, night, multiplayer (all use vanilla-driven
   uniforms, but not exercised).

## Manual verification script (for the owner)

1. Import the `.mrpack` (or manual install per README). Launch → expect green chat
   message "jelly shader pack installed & enabled".
2. Create a flat grass world, noon. Look around: grass should read as saturated
   lime jelly with wet sparkle; dirt cross-section as caramel jelly with crisp pixels.
3. Find water: thick green gel with animated cellular ripples, sky reflection at
   grazing angles, refraction of the bottom, depth-darkening to deep emerald.
4. `/summon creeper`: green gel creature, pixel face readable inside the gel, rim light.
5. Hold a diamond pickaxe: jelly-glass head (refraction, rim highlights), wooden handle.
6. Press **J**: config screen opens; "Reinstall shader pack" works.
7. Iris settings: switch Low/Medium/High/Ultra — FPS should step accordingly.
8. Disable Iris → game still runs (mod-only gloss look + one-time hint).
9. Relaunch → no duplicate install (marker files), pack stays selected.
10. F3: no recurring exceptions/warnings in the log.

## Known limitations (by design, documented)

- Creeper gel is "fake translucency" (tint + glow + rim) on opaque geometry — real
  background refraction for entities is not implemented in v0.1.
- Realistic hand MESH is not implemented (shader-side skin treatment only); the
  bundled art pack + shaders give the vanilla arm a wet-gloss skin treatment.
- Jelly wobble is ambient sway only (no gameplay-impulse damped springs — Iris
  cannot receive gameplay event uniforms; would need mod-side vertex hooks, roadmap).
- No foam/meniscus edge on liquid-block contact lines yet.
- No TAA/DOF/motion blur (deliberate: pixel crispness + readability first).
