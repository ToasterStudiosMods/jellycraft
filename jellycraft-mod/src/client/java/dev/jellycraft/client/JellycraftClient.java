package dev.jellycraft.client;

import dev.jellycraft.client.config.JellycraftConfigScreen;
import dev.jellycraft.client.iris.IrisCompat;
import dev.jellycraft.client.iris.ShaderPackAutoInstaller;
import dev.jellycraft.config.JellycraftConfig;
import dev.jellycraft.util.JcLog;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientLifecycleEvents;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.minecraft.ChatFormatting;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.Identifier;
import org.lwjgl.glfw.GLFW;

/**
 * Client init: config keybind (J by default), one-step shader pack install on
 * first run, graceful Iris-missing notice, and periodic pack-state reporting.
 */
public final class JellycraftClient implements ClientModInitializer {
        private static final KeyMapping.Category JC_CATEGORY =
                        KeyMapping.Category.register(Identifier.fromNamespaceAndPath("jellycraft", "main"));
        private static KeyMapping configKey;
        private boolean installAnnounced = false;

        @Override
        public void onInitializeClient() {
                configKey = KeyBindingHelper.registerKeyBinding(
                                new KeyMapping("key.jellycraft.config", GLFW.GLFW_KEY_J, JC_CATEGORY));
                JcLog.info("JELLYCRAFT client init (config key: J)");

                // One-step install runs when the client is fully started (Iris initialized by then).
                ClientLifecycleEvents.CLIENT_STARTED.register(client -> {
                        ShaderPackAutoInstaller.Result result =
                                        ShaderPackAutoInstaller.run(JellycraftConfig.get());
                        JcLog.info("Shader pack installer result: {}", result);
                        announceOnce(client, result);
                });

                // Keybind handling + one-time hint scheduling.
                ClientTickEvents.END_CLIENT_TICK.register(client -> {
                        while (configKey != null && configKey.consumeClick()) {
                                if (client.screen == null) {
                                        client.setScreen(new JellycraftConfigScreen(null));
                                }
                        }
                        if (!installAnnounced && client.player != null) {
                                installAnnounced = true;
                                lateHint(client);
                        }
                });
        }

        private static void announceOnce(Minecraft client, ShaderPackAutoInstaller.Result result) {
                if (client.player == null) {
                        return; // title screen: no chat yet; the late hint covers the in-game case
                }
                if (result == ShaderPackAutoInstaller.Result.INSTALLED) {
                        client.player.displayClientMessage(Component.literal(
                                        "JELLYCRAFT: jelly shader pack installed & enabled. Enjoy the wobble.")
                                        .withStyle(ChatFormatting.GREEN), false);
                }
        }

        private void lateHint(Minecraft client) {
                JellycraftConfig cfg = JellycraftConfig.get();
                if (!cfg.showIrisHint) {
                        return;
                }
                cfg.showIrisHint = false; // one-time only
                cfg.save();
                if (!IrisCompat.isIrisInstalled()) {
                        client.player.displayClientMessage(Component.literal(
                                        "JELLYCRAFT: Iris is not installed — world uses the built-in gloss look only. "
                                                        + "Install Iris + Sodium 1.10.8/0.8.14 for 1.21.11 and the bundled "
                                                        + "Jellycraft shader pack (already in shaderpacks/) for the full jelly world.")
                                        .withStyle(ChatFormatting.YELLOW), false);
                } else if (!IrisCompat.isPackInUse()) {
                        client.player.displayClientMessage(Component.literal(
                                        "JELLYCRAFT: another shader pack is active. Select 'Jellycraft-Shaders-v0.1.0.zip' "
                                                        + "in the Iris screen (J → Open Iris shader packs) for the jelly world.")
                                        .withStyle(ChatFormatting.YELLOW), false);
                } else {
                        client.player.displayClientMessage(Component.literal(
                                        "JELLYCRAFT active — everything is jelly. Press J for settings.")
                                        .withStyle(ChatFormatting.GREEN), false);
                }
        }
}
