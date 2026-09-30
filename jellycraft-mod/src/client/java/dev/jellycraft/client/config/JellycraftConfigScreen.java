package dev.jellycraft.client.config;

import dev.jellycraft.config.JellycraftConfig;
import dev.jellycraft.client.iris.IrisCompat;
import dev.jellycraft.client.iris.ShaderPackAutoInstaller;
import net.minecraft.ChatFormatting;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;

/**
 * Minimal, crash-proof JELLYCRAFT config screen (§14). Opened with the J key
 * (configurable) or through ModMenu when present. Every control writes
 * straight through to {@link JellycraftConfig} and saves immediately.
 */
public final class JellycraftConfigScreen extends Screen {
        private static final int BUTTON_W = 220;
        private static final int BUTTON_H = 20;

        private final Screen parent;

        public JellycraftConfigScreen(Screen parent) {
                super(Component.translatable("jellycraft.config.title"));
                this.parent = parent;
        }

        @Override
        protected void init() {
                JellycraftConfig cfg = JellycraftConfig.get();
                int x = this.width / 2 - BUTTON_W / 2;
                int y = 48;

                addRenderableWidget(button(x, y, autoInstallLabel(cfg), b -> {
                        cfg.autoInstallShaderPack = !cfg.autoInstallShaderPack;
                        cfg.save();
                        b.setMessage(autoInstallLabel(cfg));
                }));
                y += 24;

                addRenderableWidget(button(x, y, autoEnableLabel(cfg), b -> {
                        cfg.autoEnableShaderPack = !cfg.autoEnableShaderPack;
                        cfg.save();
                        b.setMessage(autoEnableLabel(cfg));
                }));
                y += 24;

                addRenderableWidget(button(x, y, wobbleLabel(cfg), b -> {
                        double[] steps = {0.0, 0.5, 1.0, 1.5, 2.0};
                        double current = cfg.wobbleIntensity;
                        int next = 0;
                        for (int i = 0; i < steps.length; i++) {
                                if (Math.abs(steps[i] - current) < 1.0e-3 && i + 1 < steps.length) {
                                        next = i + 1;
                                }
                        }
                        cfg.wobbleIntensity = steps[next];
                        cfg.reduceMotion = cfg.wobbleIntensity == 0.0;
                        cfg.save();
                        b.setMessage(wobbleLabel(cfg));
                }));
                y += 24;

                addRenderableWidget(button(x, y, handStyleLabel(cfg), b -> {
                        cfg.handStyle = cfg.handStyle.equals("realistic") ? "vanilla" : "realistic";
                        cfg.save();
                        b.setMessage(handStyleLabel(cfg));
                }));
                y += 24;

                addRenderableWidget(button(x, y, Component.translatable("jellycraft.config.reinstall")
                                .append(" (" + ShaderPackAutoInstaller.class.getSimpleName() + ")"), b -> {
                        ShaderPackAutoInstaller.Result result = ShaderPackAutoInstaller.forceReinstall(JellycraftConfig.get());
                        if (this.minecraft != null && this.minecraft.player != null) {
                                this.minecraft.player.displayClientMessage(
                                                Component.literal("JELLYCRAFT: shader pack reinstall → " + result), false);
                        }
                }));
                y += 24;

                if (IrisCompat.isIrisInstalled()) {
                        addRenderableWidget(button(x, y, Component.translatable("jellycraft.config.openiris"), b -> {
                                Object irisScreen = IrisCompat.openIrisScreenObject(this);
                                if (irisScreen instanceof Screen screen && this.minecraft != null) {
                                        this.minecraft.setScreen(screen);
                                }
                        }));
                        y += 24;
                } else {
                        Button noIris = button(x, y, Component.translatable("jellycraft.config.noiris")
                                        .withStyle(ChatFormatting.GRAY), b -> {
                        });
                        noIris.active = false;
                        addRenderableWidget(noIris);
                        y += 24;
                }

                addRenderableWidget(button(x, y, Component.translatable("gui.done"), b -> onClose()));
        }

        private static Component autoInstallLabel(JellycraftConfig cfg) {
                return Component.translatable("jellycraft.config.autoinstall")
                                .append(": " + (cfg.autoInstallShaderPack ? "ON" : "OFF"));
        }

        private static Component autoEnableLabel(JellycraftConfig cfg) {
                return Component.translatable("jellycraft.config.autoenable")
                                .append(": " + (cfg.autoEnableShaderPack ? "ON" : "OFF"));
        }

        private static Component wobbleLabel(JellycraftConfig cfg) {
                return Component.translatable("jellycraft.config.wobble")
                                .append(": " + Math.round(cfg.wobbleIntensity * 100) + "%");
        }

        private static Component handStyleLabel(JellycraftConfig cfg) {
                return Component.translatable("jellycraft.config.hand")
                                .append(": " + cfg.handStyle);
        }

        private Button button(int x, int y, Component label, Button.OnPress onPress) {
                return Button.builder(label, onPress).bounds(x, y, BUTTON_W, BUTTON_H).build();
        }

        @Override
        public void render(GuiGraphics guiGraphics, int mouseX, int mouseY, float partialTick) {
                super.render(guiGraphics, mouseX, mouseY, partialTick);
                guiGraphics.drawCenteredString(this.font, this.title, this.width / 2, 24, 0xFFFFFF);
                guiGraphics.drawCenteredString(this.font,
                                Component.translatable("jellycraft.config.hint"), this.width / 2, 34, 0x999999);
        }

        @Override
        public void onClose() {
                if (this.minecraft != null) {
                        this.minecraft.setScreen(parent);
                }
        }
}
