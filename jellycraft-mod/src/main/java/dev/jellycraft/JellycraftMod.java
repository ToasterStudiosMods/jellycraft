package dev.jellycraft;

import dev.jellycraft.material.MaterialReloadListener;
import dev.jellycraft.util.JcLog;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.resource.ResourceManagerHelper;
import net.fabricmc.fabric.api.resource.v1.ResourceLoader;
import net.fabricmc.fabric.api.resource.v1.pack.PackActivationType;
import net.fabricmc.loader.api.FabricLoader;
import net.minecraft.resources.Identifier;
import net.minecraft.server.packs.PackType;

/**
 * JELLYCRAFT — "Minecraft, but everything is made of jelly."
 *
 * <p>Common init: registers the built-in resource pack (the jelly art:
 * realistic hand model, glass pickaxe, material manifest) and the material
 * manifest reload listener. All world shading lives in the bundled Iris
 * shader pack; this mod owns materials, install automation, config and the
 * mod-side render hooks.</p>
 */
public final class JellycraftMod implements ModInitializer {
        public static final String MOD_ID = "jellycraft";

        @Override
        public void onInitialize() {
                // Built-in resource pack "jellycraft:jelly" → resourcepacks/jelly/ inside the mod jar.
                // Verified mechanism (Fabric API 0.141.6): ResourceLoader.registerBuiltinPack
                // resolves "resourcepacks/" + id path. DEFAULT_ENABLED = enabled on first launch,
                // user may still disable it in the pack screen.
                FabricLoader.getInstance().getModContainer(MOD_ID).ifPresent(container -> {
                        boolean ok = ResourceLoader.registerBuiltinPack(
                                        Identifier.fromNamespaceAndPath(MOD_ID, "jelly"),
                                        container,
                                        PackActivationType.DEFAULT_ENABLED);
                        JcLog.info("Built-in JELLYCRAFT resource pack registration: {}", ok ? "ok" : "already registered");
                });

                // Hot-reloadable material manifest (assets/jellycraft/materials/materials.json).
                ResourceManagerHelper.get(PackType.CLIENT_RESOURCES)
                                .registerReloadListener(new MaterialReloadListener());

                JcLog.info("JELLYCRAFT initialized — the world is jelly. (Iris installed: {}, Sodium installed: {})",
                                FabricLoader.getInstance().isModLoaded("iris"),
                                FabricLoader.getInstance().isModLoaded("sodium"));
        }
}
