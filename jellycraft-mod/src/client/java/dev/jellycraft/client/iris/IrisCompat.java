package dev.jellycraft.client.iris;

import dev.jellycraft.util.JcLog;
import net.fabricmc.loader.api.FabricLoader;

/**
 * All Iris touch-points live here. {@link IrisBridge} is only classloaded when
 * the {@code iris} mod is present, so a missing Iris can never produce a
 * NoClassDefFoundError — the graceful-fallback requirement (§0.4, §16).
 *
 * <p>API surface verified against the real Iris 1.10.8+mc1.21.11 jar via javap:
 * IrisApi v0 (isShaderPackInUse / getConfig / openMainIrisScreenObj),
 * Iris.getIrisConfig(), Iris.getShaderpacksDirectory(), IrisConfig
 * (setShaderPackName / setShadersEnabled / save), Iris.reload().</p>
 */
public final class IrisCompat {
	private static final boolean IRIS_INSTALLED = FabricLoader.getInstance().isModLoaded("iris");

	private IrisCompat() {
	}

	public static boolean isIrisInstalled() {
		return IRIS_INSTALLED;
	}

	public static boolean isPackInUse() {
		return IRIS_INSTALLED && IrisBridge.packInUse();
	}

	public static boolean areShadersEnabled() {
		return IRIS_INSTALLED && IrisBridge.areShadersEnabled();
	}

	public static java.nio.file.Path getShaderpacksDirectory() {
		return IRIS_INSTALLED ? IrisBridge.shaderpacksDirectory() : null;
	}

	/**
	 * Selects and enables a shader pack in Iris and saves the config.
	 * Only call after client start (Iris is initialized by then).
	 */
	public static boolean selectShaderPack(String packFileName) {
		if (!IRIS_INSTALLED) {
			return false;
		}
		try {
			IrisBridge.selectShaderPack(packFileName);
			return true;
		} catch (Throwable t) {
			JcLog.warn("Could not select shader pack {} in Iris: {}", packFileName, t.toString());
			return false;
		}
	}

	/** Opens the Iris "Shader Packs" screen from our config screen (official API). */
	public static Object openIrisScreenObject(Object parentScreen) {
		if (!IRIS_INSTALLED) {
			return null;
		}
		try {
			return IrisBridge.openMainScreen(parentScreen);
		} catch (Throwable t) {
			JcLog.warn("Could not open Iris screen: {}", t.toString());
			return null;
		}
	}

	/** Bridge class — NEVER reference when Iris is absent. */
	private static final class IrisBridge {
		static boolean packInUse() {
			return net.irisshaders.iris.api.v0.IrisApi.getInstance().isShaderPackInUse();
		}

		static boolean areShadersEnabled() {
			return net.irisshaders.iris.api.v0.IrisApi.getInstance().getConfig().areShadersEnabled();
		}

		static java.nio.file.Path shaderpacksDirectory() {
			return net.irisshaders.iris.Iris.getShaderpacksDirectory();
		}

		static void selectShaderPack(String packFileName) throws Exception {
			net.irisshaders.iris.config.IrisConfig config = net.irisshaders.iris.Iris.getIrisConfig();
			config.setShaderPackName(packFileName);
			config.setShadersEnabled(true);
			config.save();
			net.irisshaders.iris.Iris.reload();
		}

		static Object openMainScreen(Object parentScreen) {
			return net.irisshaders.iris.api.v0.IrisApi.getInstance().openMainIrisScreenObj(parentScreen);
		}
	}
}
