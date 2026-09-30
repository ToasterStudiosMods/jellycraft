package dev.jellycraft.client.iris;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;

import dev.jellycraft.config.JellycraftConfig;
import dev.jellycraft.util.JcLog;
import net.fabricmc.loader.api.FabricLoader;

/**
 * One-step install (§0.6 of the master spec):
 *
 * <ol>
 *   <li>Copies the bundled shader pack zip (inside this mod jar at
 *       {@code assets/jellycraft/shaderpacks/jellycraft-shaders.zip}) into the
 *       game's {@code shaderpacks/} folder.</li>
 *   <li>Re-copies only when the bundled version/hash changes — never clobbers
 *       a same-version copy the user may have edited.</li>
 *   <li>On first run only, selects + enables the pack in Iris through the
 *       verified Iris config API and remembers that it did (marker file), so
 *       the user's later pack choice is never overridden.</li>
 *   <li>If Iris is missing, the zip is still copied and a one-time chat hint
 *       explains what to install.</li>
 * </ol>
 *
 * <p>Never crashes: every failure path logs and falls back to manual install
 * instructions (zip also ships on the download site).</p>
 */
public final class ShaderPackAutoInstaller {
        private static final String BUNDLED_RESOURCE = "/" + "assets/jellycraft/shaderpacks/jellycraft-shaders.zip";
        private static final String PACK_FILE_NAME = "Jellycraft-Shaders-v0.1.0.zip";
        private static final String MARKER_DIR = "jellycraft";
        private static final String COPY_MARKER = "shaderpack-copied.txt";
        private static final String ENABLE_MARKER = "shaderpack-enabled.txt";

        private ShaderPackAutoInstaller() {
        }

        /** Runs once per client start, after the client is ready (Iris initialized). */
        public static Result run(JellycraftConfig config) {
                Path gameDir = FabricLoader.getInstance().getGameDir();
                Path shaderpacks = resolveShaderpacksDir(gameDir);
                Path markerDir = gameDir.resolve("config").resolve(MARKER_DIR);

                if (shaderpacks == null) {
                        return Result.FAILED_NO_DIR;
                }

                // 1) Copy the zip if needed (versioned marker stores sha256 of the bundled zip).
                try {
                        Files.createDirectories(shaderpacks);
                        Files.createDirectories(markerDir);
                } catch (IOException e) {
                        JcLog.warn("Cannot create shaderpacks/config dirs: {}", e.toString());
                        return Result.FAILED_NO_DIR;
                }

                String bundledHash;
                try {
                        bundledHash = sha256OfBundled();
                } catch (IOException e) {
                        JcLog.warn("Bundled shader pack zip is missing/corrupt inside the mod jar ({}); skipping install. "
                                        + "Manual zip is available on the JELLYCRAFT download page.", e.toString());
                        return Result.FAILED_MISSING_ZIP;
                }

                boolean copied = false;
                if (config.autoInstallShaderPack) {
                        copied = copyIfNeeded(shaderpacks, markerDir, bundledHash);
                }

                // 2) First-run auto-enable through Iris (never re-forced afterwards).
                boolean enabledNow = false;
                if (config.autoInstallShaderPack && config.autoEnableShaderPack && IrisCompat.isIrisInstalled()) {
                        Path enableMarker = markerDir.resolve(ENABLE_MARKER);
                        if (!Files.exists(enableMarker)) {
                                if (IrisCompat.selectShaderPack(PACK_FILE_NAME)) {
                                        try {
                                                Files.writeString(enableMarker, "enabled " + PACK_FILE_NAME + " hash " + bundledHash);
                                        } catch (IOException ignored) {
                                                // marker write failure only means we may try enabling again next run; harmless
                                        }
                                        enabledNow = true;
                                        JcLog.info("JELLYCRAFT shader pack {} installed and enabled in Iris (first run)", PACK_FILE_NAME);
                                } else {
                                        JcLog.warn("Iris could not be switched to the JELLYCRAFT pack — select it manually in the Iris screen");
                                }
                        }
                }

                if (copied || enabledNow) {
                        return Result.INSTALLED;
                }
                return Result.ALREADY_DONE;
        }

        private static Path resolveShaderpacksDir(Path gameDir) {
                Path irisDir = IrisCompat.getShaderpacksDirectory();
                if (irisDir != null) {
                        return irisDir;
                }
                return gameDir.resolve("shaderpacks");
        }

        private static boolean copyIfNeeded(Path shaderpacks, Path markerDir, String bundledHash) {
                Path target = shaderpacks.resolve(PACK_FILE_NAME);
                Path copyMarker = markerDir.resolve(COPY_MARKER);
                String previousHash = null;
                try {
                        if (Files.exists(copyMarker)) {
                                previousHash = Files.readString(copyMarker).trim();
                        }
                } catch (IOException ignored) {
                        previousHash = null;
                }

                if (previousHash != null && previousHash.equals(bundledHash) && Files.exists(target)) {
                        return false; // same bundled version already copied — never overwrite (user may have edited)
                }

                try (InputStream in = ShaderPackAutoInstaller.class.getResourceAsStream(BUNDLED_RESOURCE)) {
                        if (in == null) {
                                JcLog.warn("Bundled shader pack resource not found: {}", BUNDLED_RESOURCE);
                                return false;
                        }
                        Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
                        Files.writeString(copyMarker, bundledHash);
                        JcLog.info("JELLYCRAFT shader pack copied to {}", target);
                        return true;
                } catch (IOException e) {
                        JcLog.warn("Could not copy shader pack (folder read-only?): {} — manual install: place the zip in {} "
                                        + "and select it in the Iris screen", e.toString(), shaderpacks);
                        return false;
                }
        }

        private static String sha256OfBundled() throws IOException {
                try (InputStream in = ShaderPackAutoInstaller.class.getResourceAsStream(BUNDLED_RESOURCE)) {
                        if (in == null) {
                                throw new IOException("resource not present");
                        }
                        try {
                                MessageDigest digest = MessageDigest.getInstance("SHA-256");
                                byte[] buf = new byte[8192];
                                int n;
                                while ((n = in.read(buf)) > 0) {
                                        digest.update(buf, 0, n);
                                }
                                StringBuilder sb = new StringBuilder();
                                for (byte b : digest.digest()) {
                                        sb.append(String.format("%02x", b));
                                }
                                return sb.toString();
                        } catch (Exception e) {
                                throw new IOException("digest error: " + e);
                        }
                }
        }

        /** Manual "Reinstall shader pack" button (config screen). Always re-copies the bundled zip. */
        public static Result forceReinstall(JellycraftConfig config) {
                Path gameDir = FabricLoader.getInstance().getGameDir();
                Path shaderpacks = resolveShaderpacksDir(gameDir);
                if (shaderpacks == null) {
                        return Result.FAILED_NO_DIR;
                }
                String bundledHash;
                try {
                        bundledHash = sha256OfBundled();
                } catch (IOException e) {
                        return Result.FAILED_MISSING_ZIP;
                }
                try {
                        Files.createDirectories(shaderpacks);
                        Path target = shaderpacks.resolve(PACK_FILE_NAME);
                        try (InputStream in = ShaderPackAutoInstaller.class.getResourceAsStream(BUNDLED_RESOURCE)) {
                                if (in == null) {
                                        return Result.FAILED_MISSING_ZIP;
                                }
                                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
                        }
                        Files.createDirectories(gameDir.resolve("config").resolve(MARKER_DIR));
                        Files.writeString(gameDir.resolve("config").resolve(MARKER_DIR).resolve(COPY_MARKER), bundledHash);
                        JcLog.info("JELLYCRAFT shader pack re-copied to {}", target);
                } catch (IOException e) {
                        JcLog.warn("Reinstall failed: {}", e.toString());
                        return Result.FAILED_NO_DIR;
                }
                if (config.autoEnableShaderPack && IrisCompat.isIrisInstalled()) {
                        // manual button = explicit user intent; also select it now
                        IrisCompat.selectShaderPack(PACK_FILE_NAME);
                        try {
                                Files.writeString(gameDir.resolve("config").resolve(MARKER_DIR).resolve(ENABLE_MARKER),
                                                "enabled " + PACK_FILE_NAME + " hash " + bundledHash);
                        } catch (IOException ignored) {
                        }
                }
                return Result.INSTALLED;
        }

        public enum Result {
                INSTALLED,
                ALREADY_DONE,
                FAILED_NO_DIR,
                FAILED_MISSING_ZIP
        }
}
