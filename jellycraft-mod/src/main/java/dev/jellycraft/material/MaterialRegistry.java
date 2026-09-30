package dev.jellycraft.material;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import dev.jellycraft.util.JcLog;

/**
 * Registry of all {@link JellyMaterial}s, loaded from
 * {@code assets/jellycraft/materials/*.json} through the client resource
 * manager (so other resource packs can override or add materials — the
 * "resource-pack friendliness" requirement).
 *
 * <p>Assignment tables (block id / block tag / entity type / item id to
 * material id) live in the same JSON folder in {@code assignments.json} and
 * are mirrored 1:1 by the shader pack's {@code block.properties},
 * {@code item.properties} and {@code entity.properties} (the documented
 * mod↔shaderpack interface contract).</p>
 */
public final class MaterialRegistry {
        public static final MaterialRegistry INSTANCE = new MaterialRegistry();

        private final Map<String, JellyMaterial> materials = new HashMap<>();
        private final Map<String, String> blockAssignments = new HashMap<>();
        private final Map<String, String> blockTagAssignments = new HashMap<>();
        private final Map<String, String> entityAssignments = new HashMap<>();
        private final Map<String, String> itemAssignments = new HashMap<>();
        private volatile long loadTimeNanos = -1;

        MaterialRegistry() {
        }

        public void clear() {
                materials.clear();
                blockAssignments.clear();
                blockTagAssignments.clear();
                entityAssignments.clear();
                itemAssignments.clear();
        }

        public void putMaterial(JellyMaterial material) {
                materials.put(material.id, material);
        }

        public JellyMaterial getMaterial(String id) {
                return materials.get(id);
        }

        public Map<String, JellyMaterial> materials() {
                return materials;
        }

        public void putBlockAssignment(String blockId, String materialId) {
                blockAssignments.put(blockId, materialId);
        }

        public void putBlockTagAssignment(String tagKey, String materialId) {
                blockTagAssignments.put(tagKey, materialId);
        }

        public void putEntityAssignment(String entityTypeId, String materialId) {
                entityAssignments.put(entityTypeId, materialId);
        }

        public void putItemAssignment(String itemId, String materialId) {
                itemAssignments.put(itemId, materialId);
        }

        public String materialForBlock(String blockId) {
                String direct = blockAssignments.get(blockId);
                return direct != null ? direct : blockAssignments.get("default");
        }

        public String materialForEntity(String entityTypeId) {
                String direct = entityAssignments.get(entityTypeId);
                return direct != null ? direct : entityAssignments.get("default");
        }

        public String materialForItem(String itemId) {
                String direct = itemAssignments.get(itemId);
                return direct != null ? direct : itemAssignments.get("default");
        }

        public Map<String, String> blockAssignments() {
                return blockAssignments;
        }

        public Map<String, String> blockTagAssignments() {
                return blockTagAssignments;
        }

        public Map<String, String> entityAssignments() {
                return entityAssignments;
        }

        public Map<String, String> itemAssignments() {
                return itemAssignments;
        }

        public int size() {
                return materials.size();
        }

        public void markLoaded(long nanos) {
                this.loadTimeNanos = nanos;
        }

        public long loadTimeNanos() {
                return loadTimeNanos;
        }

        /**
         * Resolves the {@code parent} chain for every material. Cycles are broken
         * by ignoring the back-edge and logging a warning (never crash on bad data).
         */
        public void resolveInheritance() {
                int depthGuard = 0;
                boolean changed = true;
                List<String> cycleBroken = new ArrayList<>();
                while (changed && depthGuard < 8) {
                        changed = false;
                        depthGuard++;
                        for (JellyMaterial m : materials.values()) {
                                if (m.parent == null || m.parent.isEmpty()) {
                                        continue;
                                }
                                JellyMaterial parent = materials.get(m.parent);
                                if (parent != null && (parent.parent == null || parent.parent.isEmpty() || materials.containsKey(parent.parent))) {
                                        // only inherit once per material per pass; parents are resolved breadth-first-ish
                                        m.inheritFrom(parent);
                                        if (!cycleBroken.contains(m.id)) {
                                                changed = true;
                                        }
                                } else if (parent == null) {
                                        JcLog.warn("Material {} references unknown parent {} — skipping inheritance", m.id, m.parent);
                                        m.parent = "";
                                        changed = true;
                                }
                        }
                }
                if (depthGuard >= 8) {
                        JcLog.warn("Material inheritance depth guard hit — possible parent cycle; some parents not applied");
                }
        }
}
