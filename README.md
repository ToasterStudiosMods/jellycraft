# JELLYCRAFT v0.1.0 — "Minecraft, but everything is made of jelly"

Transforms Minecraft Java **1.21.11** into a jelly world: glossy translucent terrain,
a clear aqua gel flood where water was, gel Creeper, jelly-glass pickaxe, wet glossy
hands — voxel geometry, pixel textures and gameplay stay 100% vanilla.

Solid terrain and block entities use a subtle **6% alpha-blended jelly transmission** by
default. It is adjustable under **Jelly Effects → Block translucency** in Iris.

## Exact pinned environment (all verified, none guessed)

| Component | Pinned version | Verified against |
|---|---|---|
| Minecraft Java | **1.21.11** | Mojang piston-meta manifest |
| Fabric Loader | **0.19.5** | meta.fabricmc.net |
| Fabric API | **0.141.6+1.21.11** | Modrinth (stable) |
| Sodium | **0.8.14 (mc1.21.11-fabric)** | Modrinth (stable; 0.8.15-beta.1 rejected) |
| Iris Shaders | **1.10.8+mc1.21.11-fabric** | Modrinth (stable) |
| Java | **25** for Gradle/Loom (mod bytecode targets 21) | Fabric Loom 1.18.2 |
| Gradle | **9.7** | Fabric Loom 1.18.2 plugin variant |

## Install — easiest (one import)

1. Install the **Prism Launcher** or **Modrinth App**.
2. Import `Jellycraft-1.21.11-0.1.0.mrpack` (Add Instance → Import).
   This creates a 1.21.11 instance with Fabric Loader 0.19.5 + Fabric API +
   Sodium 0.8.14 + Iris 1.10.8 + the JELLYCRAFT mod.
3. Launch. On first start the mod **copies its bundled shader pack into
   `shaderpacks/`, selects and enables it in Iris, and enables the bundled
   JELLYCRAFT art resource pack** — you should see a green chat message
   confirming. That's it.

## Install — manual (mods folder)

1. Create a Fabric 1.21.11 profile (Fabric Loader 0.19.5) with **Fabric API**,
   **Sodium 0.8.14** and **Iris 1.10.8** (Iris requires Sodium).
2. Drop `jellycraft-0.1.0.jar` into `mods/`.
3. Launch once — the mod auto-installs + auto-enables its shader pack (first run only,
   never re-forced). If you skipped Iris, the game still runs with the mod-only gloss look.
4. Recommended shader preset: **Medium** on integrated GPUs / laptops,
   **High** on discrete GPUs, **Ultra** to see the quality ceiling.

## What's inside

- `jellycraft-0.1.0.jar` — the Fabric mod (client-side): material registry
  (data-driven, hot-reloadable), built-in art resource pack, one-step Iris
  shader-pack install, config screen (press **J** in game).
- `Jellycraft-Shaders-v0.1.0.zip` — the Iris shader pack (also bundled in the jar).
  Select it in Options → Video Settings → Shader Packs… if you install manually.
- `Jellycraft-Art-v0.1.0.zip` — standalone art resource pack (jelly-glass pickaxe
  model + textures, material manifest). Bundled + auto-enabled by the mod.
- `jellycraft-src-0.1.0.zip` — full source (mod + shaders), MIT.
- `Jellycraft-1.21.11-0.1.0.mrpack` — one-import Modrinth modpack.
- `PROGRESS.md`, `QA-REPORT.md`, `OPTIMIZATION-REPORT.md` — the project ledger and honest reports.

## Building from source

Binary distributions are intentionally not updated in Git commits. GitHub Actions builds the
Fabric JAR and publishes it as a workflow artifact; locally run `gradle --no-daemon build` from
`jellycraft-mod`. The build generates and embeds `jellycraft-shaders.zip` from the text shader
sources, so no nested ZIP needs to be checked in.

## Shader presets (Iris → Shader Pack Settings)

| Preset | Shadows | SSR | Refraction | Caustics | Target overhead |
|---|---|---|---|---|---|
| Low | off | off | on (cheap) | off | ~10% frame time |
| Medium | off | off | on | off | ~25% |
| High | on | on | on | on | ~50% |
| Ultra | on | on (32 steps) | on | on | uncapped |

Comfort: in the shader settings, set **Wobble strength → 0%** and **Player bend strength → 0%**
to disable all jelly motion while keeping the jelly look. The default
color grade preserves a blue sky and normal daylight saturation; jelly comes from deformation,
wet highlights and refraction rather than a yellow-green world filter.

## Verified vs UNTESTED — read this

Everything in this build **compiles for real** against the actual Minecraft 1.21.11
mapped jar with pinned dependencies, and all Iris/Fabric APIs used were verified by
inspecting the real mod jars. However, **this build has not been run inside the actual
game** (the build machine has no GPU/display). See `QA-REPORT.md` for the exact
UNTESTED list and the 15-minute manual verification script.

## Licensing

- JELLYCRAFT code, shaders, art: **MIT**.
- Not affiliated with Mojang, IrisShaders or Sodium. Their mods are NOT redistributed
  inside the JELLYCRAFT jar — the .mrpack references official Modrinth CDN files.
