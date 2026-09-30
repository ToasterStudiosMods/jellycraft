package dev.jellycraft.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Central logging for JELLYCRAFT. Every notable runtime decision (pack install,
 * fallbacks, material loading stats) is logged so owners can verify behaviour
 * from the game log exactly as the progress ledger requires.
 */
public final class JcLog {
	public static final Logger LOGGER = LoggerFactory.getLogger("JELLYCRAFT");

	private JcLog() {
	}

	public static void info(String msg, Object... args) {
		LOGGER.info(msg, args);
	}

	public static void warn(String msg, Object... args) {
		LOGGER.warn(msg, args);
	}

	public static void error(String msg, Object... args) {
		LOGGER.error(msg, args);
	}
}
