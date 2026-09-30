package dev.jellycraft.config;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import dev.jellycraft.util.JcLog;
import net.fabricmc.loader.api.FabricLoader;

/**
 * JELLYCRAFT client configuration, persisted as
 * {@code config/jellycraft.json}. Every value is clamped when loaded so a
 * corrupt file can never crash the game (§14, §16 of the master spec).
 */
public final class JellycraftConfig {
	private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
	private static final Path CONFIG_PATH = FabricLoader.getInstance().getConfigDir()
			.resolve("jellycraft.json");

	// ---- One-step install (§0.6) ----
	/** Copy the bundled Iris shader pack zip into shaderpacks/ on first run. */
	public boolean autoInstallShaderPack = true;
	/** Additionally select + enable it in Iris on first run only. */
	public boolean autoEnableShaderPack = true;
	/** Re-copy the zip when the bundled version changes (never overwrite user edits of other packs). */
	public boolean updateBundledShaderPack = true;

	// ---- Jelly look & comfort ----
	/** Multiplier on all jelly wobble/squish amplitudes. 0 = static. */
	public double wobbleIntensity = 1.0;
	/** Comfort option: disables wobble/ripple animation, keeps the jelly look. */
	public boolean reduceMotion = false;

	// ---- Hands ----
	/** "realistic" = bundled realistic hand mesh (when the render hook is active), "vanilla" = stock arm. */
	public String handStyle = "realistic";
	/** "default" | "player" (tint from player skin) | "vanilla". */
	public String skinToneSource = "default";

	// ---- Integration & notices ----
	/** Show the one-time chat hint when Iris is missing or another pack is selected. */
	public boolean showIrisHint = true;
	/** Quality preset written into the shader pack options on first install. LOW/MEDIUM/HIGH/ULTRA. */
	public String defaultPreset = "MEDIUM";
	/** Debug: log per-material resolution and pass timings (verbose). */
	public boolean debugLogging = false;

	private static JellycraftConfig instance;

	public static JellycraftConfig get() {
		if (instance == null) {
			instance = load();
		}
		return instance;
	}

	public static JellycraftConfig load() {
		JellycraftConfig config = new JellycraftConfig();
		if (Files.exists(CONFIG_PATH)) {
			try {
				String json = Files.readString(CONFIG_PATH);
				JellycraftConfig read = GSON.fromJson(json, JellycraftConfig.class);
				if (read != null) {
					config = read;
				}
			} catch (Exception e) {
				JcLog.warn("Could not read {} — using defaults ({})", CONFIG_PATH, e.toString());
			}
		}
		config.clamp();
		return config;
	}

	public void save() {
		clamp();
		try {
			Files.createDirectories(CONFIG_PATH.getParent());
			Files.writeString(CONFIG_PATH, GSON.toJson(this));
		} catch (IOException e) {
			JcLog.warn("Could not save {}: {}", CONFIG_PATH, e.toString());
		}
	}

	/** Clamps every value into a safe range — invalid values never crash. */
	public void clamp() {
		autoInstallShaderPack = autoInstallShaderPack; // boolean, always safe
		wobbleIntensity = clamp(wobbleIntensity, 0.0, 3.0);
		handStyle = allowed(handStyle, List.of("realistic", "vanilla"), "realistic");
		skinToneSource = allowed(skinToneSource, List.of("default", "player", "vanilla"), "default");
		defaultPreset = allowed(defaultPreset.toUpperCase(), List.of("LOW", "MEDIUM", "HIGH", "ULTRA"), "MEDIUM");
	}

	public boolean reduceMotionEffective() {
		return reduceMotion || wobbleIntensity <= 0.0;
	}

	private static double clamp(double v, double min, double max) {
		return Math.max(min, Math.min(max, v));
	}

	private static String allowed(String value, List<String> allowed, String fallback) {
		return value != null && allowed.contains(value) ? value : fallback;
	}
}
