# JELLYCRAFT — Progress Ledger

**Project:** "Minecraft, but everything is made of jelly" — Minecraft Java **1.21.11** · Fabric · Iris + Sodium
**Sandbox rebuilt from scratch** (previous session's sandbox was wiped; this ledger starts fresh at 2026-09-30 UTC.)

---

## ⚠️ REFERENCE IMAGE STATUS (Section 0.2 declaration)

**No reference image files are present in this environment.** The master prompt states four reference
images were supplied, but no attachments exist in the current session and the sandbox was wiped
(no leftovers to recover). Per Section 0.2 rule 5, this is declared loudly:

- **Fallback:** the written analysis in Section 2 of the master prompt is used as the authoritative
  visual reference.
- **All visual judgements in this build are marked LOW-CONFIDENCE (no side-by-side image comparison
  was possible).**
- Once the owner can open the game next to the four references, the per-material constants
  (colors, gloss, sparkle) in `materials/*.json` are the tuning surface — everything is data-driven
  specifically so this gap can be closed without code changes.

---

## Phase 1 — Environment Discovery Report (VERIFIED, 2026-09-30)

All version numbers below were queried live from **Modrinth API**, **fabricmc.net meta**,
**Maven FabricMC**, and **Mojang piston-meta**. Nothing is guessed.

### Pinned toolchain

| Component | Pinned version | Source of truth |
|---|---|---|
| Minecraft | **1.21.11** (release 2025-12-09) | piston-meta version_manifest_v2 (sha1 `4f6bd938…`) |
| Fabric Loader | **0.19.5** | meta.fabricmc.net/v2/versions/loader |
| Fabric API | **0.141.6+1.21.11** | Modrinth `fabric-api` (latest stable for 1.21.11) |
| Yarn (checked only) | 1.21.11+build.6 exists | meta.fabricmc.net — **NOT used; we use Mojang mappings** (see decision D2) |
| Sodium | **mc1.21.11-0.8.14-fabric** (stable) | Modrinth `sodium` (0.8.15-beta.1 exists; beta rejected) |
| Iris | **1.10.8+mc1.21.11-fabric** (stable, 2026-09-29) | Modrinth `iris` |
| Loom | **1.18.2** (plugin id `net.fabricmc.fabric-loom-remap`) | maven.fabricmc.net maven-metadata |
| Gradle | **9.7.1** | fabric-example-mod `1.21` branch wrapper |
| Java | **21** (Temurin 21.0.12.1, portable install — sandbox had JRE only) | local build JDK |

### Verified APIs (from actual jars, via `javap` — no hallucination)

**Iris 1.10.8+mc1.21.11 (downloaded jar `/tmp/iris.jar`):**
- `net.irisshaders.iris.api.v0.IrisApi` — `getInstance()`, `isShaderPackInUse()`,
  `isRenderingShadowPass()`, `getConfig()` → `IrisApiConfig` (`areShadersEnabled()`,
  `setShadersEnabledAndApply(boolean)`), `getSunPathRotation()`, `openMainIrisScreenObj(Object)`.
- `net.irisshaders.iris.Iris` — static `getIrisConfig()`, `getShaderpacksDirectory()`,
  `getCurrentPack()`, `getCurrentPackName()`, `reload()` (throws IOException).
- `net.irisshaders.iris.config.IrisConfig` — `setShaderPackName(String)`, `setShadersEnabled(boolean)`,
  `save()`, `load()`, `areShadersEnabled()`.
- → **Auto-install/auto-enable mechanism is REAL and verified**: copy zip → `Iris.getShaderpacksDirectory()`,
  then `Iris.getIrisConfig().setShaderPackName(...); setShadersEnabled(true); save(); Iris.reload();`.
- Iris `fabric.mod.json` depends on `sodium 0.8.x` — matches pinned Sodium 0.8.14.

**Fabric API 0.141.6 (downloaded jar, nested modules inspected):**
- `net.fabricmc.fabric.api.resource.v1.ResourceLoader.registerBuiltinPack(ResourceLocation, ModContainer, PackActivationType)`
  and the `(…, Component, PackActivationType)` overload; `PackActivationType.{NORMAL, DEFAULT_ENABLED, ALWAYS_ENABLED}`
  → built-in resource pack registration mechanism verified (used with `DEFAULT_ENABLED`).
- `ResourceManagerHelper.get(ResourceType).registerReloadListener(...)` (v0) verified for the
  material-JSON reload listener.

**fabric-example-mod (`1.21` branch, fetched from GitHub):** current template uses
`net.fabricmc.fabric-loom-remap` plugin, `loom.officialMojangMappings()`, split environment
source sets, Gradle 9.7.1 — this is the scaffold JELLYCRAFT's Gradle setup mirrors.

### Architecture decisions

- **D1 — Hybrid delivery, as fixed by the owner:** Fabric mod (materials/registry/config/Iris
  integration/hand+entity model hooks) + Iris shader pack (all world shading) + bundled resource
  pack (hand model, glass pickaxe model, PBR-ish maps) inside the mod jar as a built-in pack.
- **D2 — Mojang mappings (Mojmap), not Yarn:** the official fabric-example-mod for the 1.21 line now
  uses `loom.officialMojangMappings()` with the `fabric-loom-remap` plugin, and 1.21.11 is the last
  release before Mojang's unobfuscated-jar transition. Matching the official template is the most
  future-proof and best-documented path. All mod code below is written in Mojmap.
- **D3 — Iris is an OPTIONAL runtime dependency:** mod detects `iris` via Fabric Loader; all Iris
  calls isolated in one classloader-guarded compat layer; never crashes without Iris (falls back to
  built-in pack gloss + one-time chat notice recommending the bundled shader pack zip).
- **D4 — Sodium is never mixed into:** terrain shading is 100% shader-pack side (Iris programs
  `gbuffers_terrain` etc.). The mod performs zero chunk-rendering mixins.
- **D5 — Creeper gel is primarily shader-side** (Iris `entity.properties` custom program:
  translucency, Fresnel, internal glow, refraction). The optional extra gel-blob layer (Ref 2
  style) would require an entity-renderer mixin — attempted only if the mapped-jar inspection
  gives a safe hook; otherwise shipped as data-gated design and documented.
- **D6 — Real build, honestly reported:** the sandbox has network + JDK, so the mod is **compiled
  for real** with Gradle against the real 1.21.11 jar. The sandbox has **no GPU/display**, so the
  game client is **NOT launched**: every runtime/visual claim is marked **UNTESTED** and a manual
  test script + scripted QA scenes are provided for the owner.

### Environment limitations (honest report)

| Capability | Status |
|---|---|
| Network (Modrinth/FabricMC/Mojang/Adoptium) | ✅ works |
| JDK 21 (Temurin portable) | ✅ installed at `/home/z/jdks/jdk-21.0.12.1+1` |
| Real Gradle build of the mod | ✅ attempted for real — see build log section |
| Launch real Minecraft client | ❌ **no GPU/display in sandbox — UNTESTED** |
| GLSL machine validation (glslangValidator) | ❌ not available — GLSL written to Iris/OptiFree-format conventions, hand-checked |
| Reference images | ❌ not present — see declaration above |

---

## Build log (most recent first)

*(entries appended per iteration below)*

---

## Iteration 1 — 2026-09-30 (second sandbox session, resumed from wipe)

**Context:** Session continued via owner message; the four reference images were
(re-)declared as attachments but **no image files exist anywhere on the filesystem**
(searched `/home/z` fully: `/home/z/my-project/upload/` is empty). The §0.2 fallback
declaration above therefore REMAINS ACTIVE: Section 2 text is the visual authority;
all visual judgements stay LOW-CONFIDENCE.

### What was done (build loop: implement → build → verify)

1. **Mod completed and REALLY BUILT.** Gradle 9.7.1 (downloaded to `.tools/`),
   Loom 1.18.2 requires JDK 25 for the build JVM → used `/home/z/jdks/jdk-25.0.4.1+1`
   (mod still targets Java 21 at runtime). `gradle build` → **BUILD SUCCESSFUL** →
   `jellycraft-0.1.0.jar` (74,265 B) + sources jar.
2. **API corrections verified against the real 1.21.11 mapped jar** (loom cache, javap) —
   these were compile errors found by the REAL compiler, exactly why "never invent APIs"
   matters:
   - `ResourceLocation` → **`net.minecraft.resources.Identifier`** (1.21.11 pre-unobfuscation rename)
   - `ResourceType` → **`net.minecraft.server.packs.PackType`**
   - `ResourcePackActivationType` → **`net.fabricmc.fabric.api.resource.v1.pack.PackActivationType`**
   - `KeyMapping` category is now a **record** `KeyMapping.Category`, registered via
     `KeyMapping.Category.register(Identifier)`; label key = `key.category.jellycraft.main`
   - `Optional.map(this::parse)` with checked Exception → restructured to lambda with try/catch
   - `MaterialRegistry` constructor un-privatized (same-package builder use)
3. **Iris shader pack written from scratch** (48 files): `shaders.properties` (4 preset
   profiles, sliders, screens, buffer formats, 2048px shadows), `block/entity/item.properties`
   (the ID contract), `lib/{settings,common,materials,jelly,sky}.glsl`, programs:
   terrain, water (gel liquid), entities(+translucent), hand(+water), clouds, skybasic,
   skytextured, textured(+lit), block(+translucent), shadow, deferred (opaque backup),
   composite (depth-validated refraction + Beer-Lambert + SSR + caustics + underwater),
   final (exposure, bloom ring, ACES, vibrance, vignette, dither).
4. **Resource pack (built-in "jelly" art pack)**: jelly-glass pickaxe — 1.21.4+ item
   definition (`minecraft:select` on `display_context`: flat icon in GUI, 3D model in
   hand), 5-element 3D model (oak handle + cream binding + glass head bar + 2 rotated
   tips), PIL-generated 16×16 pixel textures (glass head with sparkle pixels + bubbles,
   binding with thin-film pixels, GUI icon), `pack.png`. `materials.json` extended with
   `jellycraft:jelly_glass` (contract sync with block ID 10010).
5. **Packaging:** mod jar, `Jellycraft-Shaders-v0.1.0.zip` (root-level contents),
   `Jellycraft-Art-v0.1.0.zip`, `jellycraft-src-0.1.0.zip`,
   `Jellycraft-1.21.11-0.1.0.mrpack` (live Modrinth CDN URLs + sha1/sha512 for
   fabric-api 0.141.6 / sodium 0.8.14 / iris 1.10.8 — beta versions filtered out,
   sodium 0.8.15-beta.1 explicitly rejected).
6. **Docs:** README (pinned versions + install), QA-REPORT (VERIFIED vs UNTESTED split
   + 10-step owner verification script), OPTIMIZATION-REPORT (built-in optimizations +
   measurement protocol + per-pass table to fill).

### Pass/fail table (this iteration)

| Item | Status | Evidence |
|---|---|---|
| Mod compiles vs real 1.21.11 | **PASS** | BUILD SUCCESSFUL, jar listing verified |
| fabric.mod.json version expansion | **PASS** | jar contains `"version": "0.1.0"` |
| Bundled shader pack in jar | **PASS** | `assets/jellycraft/shaderpacks/jellycraft-shaders.zip` 42,572 B |
| Builtin resource pack in jar | **PASS** | `resourcepacks/jelly/**` complete |
| Shader pack zip at archive root | **PASS** | unzip listing: `shaders/` top-level |
| Shader pack compiles in Iris | **UNTESTED** | no GPU/GLSL validator in sandbox |
| In-game visuals vs references | **UNTESTED** | no game launch possible; refs absent |
| Performance budgets | **UNTESTED** | no GPU; protocol documented |
| One-step install runtime behavior | **UNTESTED** | code + APIs javap-verified only |

### Decisions this session

- **D7 — JDK 25 toolchain / Java 21 target:** Loom 1.18.2 requires JVM ≥25 to run the
  build; the mod itself still declares Java 21 (runtime requirement unchanged).
- **D8 — GLSL style:** `#version 330 compatibility` + `RENDERTARGETS` comments +
  `gtexture`/`lightmap` samplers + classic `gl_*` builtins (Iris-patched) — the most
  battle-tested convention set for Iris; every program shares boilerplate so any
  Iris-side compile error is a one-file fix.
- **D9 — Refraction architecture:** deferred pass snapshots the opaque scene into
  colortex3 between opaque and translucent rendering (Iris-supported); gel writes
  mask+spec (colortex4) + absorption (colortex2) + ripple normals (colortex1); the
  composite replaces gel pixels with depth-validated refracted+absorbed color.
  Depth validation rule: sample rejected if its opaque depth is nearer than the gel
  surface (no foreground smear, spec §6.5).
- **D10 — Creeper gel is fake-translucency in v0.1** (opaque geometry + deep tint +
  internal glow + rim + wet coat): entity background-refraction needs Iris custom
  entity program routing that could not be verified risk-free without running the
  game. Documented as limitation; data-driven upgrade path exists.
- **D11 — Hand treatment is shader-side skin material in v0.1** (warm subsurface wrap,
  wet clearcoat, no sparkle): a custom realistic hand MESH requires entity-renderer
  mixins that are crash-risky untested; §14 matrix already defines "vanilla arm w/
  gloss" as the LOW tier so this ships as that tier with the mesh as roadmap.

### Next actions

- Owner: run the 10-step verification script (QA-REPORT) and the perf protocol
  (OPTIMIZATION-REPORT); send `latest.log` + screenshots (esp. any Iris compile error).
- v0.2 roadmap: impulse-driven wobble via mod-side hooks, real creeper refraction,
  realistic hand mesh, foam/meniscus, auto-quality governor, OIT at ULTRA.
