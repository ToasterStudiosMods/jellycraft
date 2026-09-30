package dev.jellycraft.material;

import java.io.BufferedReader;
import java.util.Map;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import dev.jellycraft.util.JcLog;
import net.fabricmc.fabric.api.resource.IdentifiableResourceReloadListener;
import net.minecraft.resources.Identifier;
import net.minecraft.server.packs.resources.Resource;
import net.minecraft.server.packs.resources.ResourceManager;
import net.minecraft.server.packs.resources.SimplePreparableReloadListener;
import net.minecraft.util.profiling.ProfilerFiller;

/**
 * Loads {@code assets/jellycraft/materials/materials.json} (the JELLYCRAFT
 * material manifest: material definitions + block/entity/item assignment
 * tables) from the client resource manager. Other resource packs can override
 * the same path to re-skin materials without code changes — the data-driven
 * requirement of the master spec (§4.1, §21).
 */
public final class MaterialReloadListener
                extends SimplePreparableReloadListener<MaterialReloadListener.LoadedManifest>
                implements IdentifiableResourceReloadListener {

        public static final Identifier MANIFEST_ID =
                        Identifier.fromNamespaceAndPath("jellycraft", "materials/materials.json");
        private static final Gson GSON = new Gson();

        @Override
        public Identifier getFabricId() {
                return Identifier.fromNamespaceAndPath("jellycraft", "materials");
        }

        @Override
        protected LoadedManifest prepare(ResourceManager manager, ProfilerFiller profiler) {
                return manager.getResource(MANIFEST_ID)
                                .map(resource -> {
                                        try {
                                                return parse(resource);
                                        } catch (Exception e) {
                                                JcLog.error("Failed to read JELLYCRAFT material manifest: {}", e.toString());
                                                return new LoadedManifest();
                                        }
                                })
                                .orElseGet(() -> {
                                        JcLog.warn("Material manifest {} not found — JELLYCRAFT materials unchanged", MANIFEST_ID);
                                        return new LoadedManifest();
                                });
        }

        private LoadedManifest parse(Resource resource) throws Exception {
                try (BufferedReader reader = resource.openAsReader()) {
                        JsonObject root = JsonParser.parseReader(reader).getAsJsonObject();
                        LoadedManifest manifest = new LoadedManifest();
                        if (root.has("materials")) {
                                for (JsonElement el : root.getAsJsonArray("materials")) {
                                        JellyMaterial material = GSON.fromJson(el, JellyMaterial.class);
                                        if (material.id == null || material.id.isEmpty()) {
                                                JcLog.warn("Skipping anonymous material entry (missing id)");
                                                continue;
                                        }
                                        if (root.has("quality_overrides") && root.getAsJsonObject("quality_overrides").has(material.id)) {
                                                JsonObject overrides = root.getAsJsonObject("quality_overrides").getAsJsonObject(material.id);
                                                for (Map.Entry<String, JsonElement> entry : overrides.entrySet()) {
                                                        material.qualityOverrides.put(entry.getKey().toUpperCase(),
                                                                        GSON.fromJson(entry.getValue(), JellyMaterial.class));
                                                }
                                        }
                                        manifest.registry.putMaterial(material);
                                }
                        }
                        if (root.has("block_assignments")) {
                                for (Map.Entry<String, JsonElement> entry : root.getAsJsonObject("block_assignments").entrySet()) {
                                        String key = entry.getKey();
                                        String value = entry.getValue().getAsString();
                                        if (key.startsWith("#")) {
                                                manifest.registry.putBlockTagAssignment(key.substring(1), value);
                                        } else {
                                                manifest.registry.putBlockAssignment(key, value);
                                        }
                                }
                        }
                        if (root.has("entity_assignments")) {
                                for (Map.Entry<String, JsonElement> entry : root.getAsJsonObject("entity_assignments").entrySet()) {
                                        manifest.registry.putEntityAssignment(entry.getKey(), entry.getValue().getAsString());
                                }
                        }
                        if (root.has("item_assignments")) {
                                for (Map.Entry<String, JsonElement> entry : root.getAsJsonObject("item_assignments").entrySet()) {
                                        manifest.registry.putItemAssignment(entry.getKey(), entry.getValue().getAsString());
                                }
                        }
                        return manifest;
                }
        }

        @Override
        protected void apply(LoadedManifest manifest, ResourceManager manager, ProfilerFiller profiler) {
                if (manifest.empty()) {
                        return; // keep previous state on failed/absent reload
                }
                MaterialRegistry target = MaterialRegistry.INSTANCE;
                target.clear();
                for (JellyMaterial material : manifest.registry.materials().values()) {
                        target.putMaterial(material);
                }
                manifest.registry.blockAssignments().forEach(target::putBlockAssignment);
                manifest.registry.blockTagAssignments().forEach(target::putBlockTagAssignment);
                manifest.registry.entityAssignments().forEach(target::putEntityAssignment);
                manifest.registry.itemAssignments().forEach(target::putItemAssignment);
                target.resolveInheritance();
                target.markLoaded(manifest.elapsedNanos);
                JcLog.info("Loaded {} JELLYCRAFT materials ({} block, {} tag, {} entity, {} item assignments)",
                                target.size(),
                                target.blockAssignments().size(),
                                target.blockTagAssignments().size(),
                                target.entityAssignments().size(),
                                target.itemAssignments().size());
        }

        static final class LoadedManifest {
                final MaterialRegistry registry = new MaterialRegistry();
                final long elapsedNanos = System.nanoTime();

                boolean empty() {
                        return registry.size() == 0;
                }
        }
}
