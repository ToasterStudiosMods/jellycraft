JELLYCRAFT — Iris Shader Pack v0.1.0
"Minecraft, but everything is made of jelly."
Target: Minecraft Java 1.21.11 · Iris 1.10.8+mc1.21.11 · Sodium 0.8.14

INSTALL
  Copy this zip (do NOT extract) into .minecraft/shaderpacks/ and select
  it in Options → Video Settings → Shader Packs… (Iris). The JELLYCRAFT
  mod does this automatically on first launch.

PRESETS
  Low / Medium / High / Ultra via the shader options screen
(Shader Packs → Jellycraft → Shader Pack Settings).

LOOK / MOTION
  Defaults deliberately preserve a clear blue Minecraft sky and normal
  daylight saturation. In JELLY_MOTION, Player bend creates a seamless,
  camera-following pressure bowl in nearby terrain and gel water; reduce its
  strength or disable it for accessibility / reduced motion.
  Solid terrain and block entities have a 6% alpha-blended jelly skin by default.
  Adjust it in Jelly Effects → Block translucency.

MATERIAL INTERFACE CONTRACT (mirrors the mod's materials.json)
  block.properties    10001 grass 10002 dirt 10003 stone 10004 sand
                      10005 wood 10006 leaves 10007 liquid(water)
                      10008 ice 10009 lava 10010 glass 10011 default
  entity.properties   10001 creeper 10002 slime 10003 hostile
                      10004 passive 10005 humanoid 10006 ender
  item.properties     10001 glass tools 10002 glass items 10003 wood tools
  Changing a material's look = edit lib/materials.glsl here AND
  assets/jellycraft/materials/materials.json in the mod (they mirror).

LICENSING
  GLSL code: MIT (c) JELLYCRAFT project. Not affiliated with Mojang,
  IrisShaders or Sodium. Minecraft must be owned legally.
