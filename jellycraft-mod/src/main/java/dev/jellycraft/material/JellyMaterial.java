package dev.jellycraft.material;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A single JELLYCRAFT material definition (Appendix A of the master spec).
 * Mirrored by the shader pack's material uniforms: the JSON is the single
 * source of truth; the shader pack reads its own copy via material programs,
 * and this registry exists for tooling, config UI display, mod-side effects
 * (wobble impulses) and for future mod-API consumers.
 *
 * <p>All fields have sane defaults so partial JSON is valid.</p>
 */
public final class JellyMaterial {
	/** Material id, e.g. "jellycraft:jelly_grass". */
	public String id = "";
	/** Parent material id for inheritance, resolved by {@link MaterialRegistry}. */
	public String parent = "";

	public float[] baseColor = {1.0f, 1.0f, 1.0f};
	public float roughness = 0.4f;
	public float metallic = 0.0f;
	public float specular = 0.5f;
	public float[] emissive = {0.0f, 0.0f, 0.0f};
	public float emissiveStrength = 0.0f;
	public float opacity = 1.0f;
	public float transmission = 0.0f;
	public float ior = 1.33f;
	public float fresnelStrength = 1.0f;
	public float subsurfaceStrength = 0.0f;
	public float[] subsurfaceColor = {1.0f, 1.0f, 1.0f};
	public float thickness = 0.5f;
	public float[] absorptionColor = {0.2f, 0.4f, 0.2f};
	public float absorptionDensity = 1.0f;
	public float refractionStrength = 0.0f;
	public float distortionStrength = 0.0f;
	public float wetness = 0.0f;
	public float clearcoat = 0.0f;
	public float clearcoatRoughness = 0.1f;
	public float reflectionIntensity = 1.0f;
	public float normalStrength = 1.0f;
	public float parallaxStrength = 0.0f;
	public float animationSpeed = 1.0f;
	public float rippleStrength = 0.0f;
	public float rippleScale = 1.0f;
	public float waveAmplitude = 0.0f;
	public float edgeGlow = 0.0f;
	public float depthFade = 0.0f;
	public float sparkleStrength = 0.0f;
	public float sparkleScale = 48.0f;
	public float textureCrispness = 1.0f;
	public float jellyStiffness = 0.8f;
	public float jellyDamping = 0.7f;
	public float jellyAmplitude = 0.005f;

	/** Per-preset overrides, keyed LOW / MEDIUM / HIGH / ULTRA. */
	public Map<String, JellyMaterial> qualityOverrides = new LinkedHashMap<>();

	/**
	 * Copies every field from {@code parent} into this material where the child
	 * still has the default value. Quality overrides recurse one level.
	 */
	public void inheritFrom(JellyMaterial parent) {
		if (parent == null) {
			return;
		}
		// Field-wise "unset" inheritance: only inherit when child keeps the class default.
		if (this.parent.isEmpty()) {
			this.parent = parent.parent;
		}
		if (equalsDefault(this.roughness, 0.4f)) {
			this.roughness = parent.roughness;
		}
		if (equalsDefault(this.metallic, 0.0f)) {
			this.metallic = parent.metallic;
		}
		if (equalsDefault(this.specular, 0.5f)) {
			this.specular = parent.specular;
		}
		if (equalsDefault(this.opacity, 1.0f)) {
			this.opacity = parent.opacity;
		}
		if (equalsDefault(this.transmission, 0.0f)) {
			this.transmission = parent.transmission;
			this.ior = equalsDefault(this.ior, 1.33f) ? parent.ior : this.ior;
			this.fresnelStrength = equalsDefault(this.fresnelStrength, 1.0f) ? parent.fresnelStrength : this.fresnelStrength;
		}
		if (equalsDefault(this.subsurfaceStrength, 0.0f)) {
			this.subsurfaceStrength = parent.subsurfaceStrength;
			this.thickness = equalsDefault(this.thickness, 0.5f) ? parent.thickness : this.thickness;
		}
		if (equalsDefault(this.absorptionDensity, 1.0f)) {
			this.absorptionDensity = parent.absorptionDensity;
		}
		if (equalsDefault(this.refractionStrength, 0.0f)) {
			this.refractionStrength = parent.refractionStrength;
			this.distortionStrength = equalsDefault(this.distortionStrength, 0.0f) ? parent.distortionStrength : this.distortionStrength;
		}
		if (equalsDefault(this.wetness, 0.0f)) {
			this.wetness = parent.wetness;
			this.clearcoat = equalsDefault(this.clearcoat, 0.0f) ? parent.clearcoat : this.clearcoat;
			this.clearcoatRoughness = equalsDefault(this.clearcoatRoughness, 0.1f) ? parent.clearcoatRoughness : this.clearcoatRoughness;
		}
		if (equalsDefault(this.sparkleStrength, 0.0f)) {
			this.sparkleStrength = parent.sparkleStrength;
			this.sparkleScale = equalsDefault(this.sparkleScale, 48.0f) ? parent.sparkleScale : this.sparkleScale;
		}
		if (equalsDefault(this.edgeGlow, 0.0f)) {
			this.edgeGlow = parent.edgeGlow;
			this.depthFade = equalsDefault(this.depthFade, 0.0f) ? parent.depthFade : this.depthFade;
		}
		if (equalsDefault(this.jellyAmplitude, 0.005f)) {
			this.jellyStiffness = parent.jellyStiffness;
			this.jellyDamping = parent.jellyDamping;
			this.jellyAmplitude = parent.jellyAmplitude;
		}
		if (equalsDefault(this.rippleStrength, 0.0f)) {
			this.rippleStrength = parent.rippleStrength;
			this.rippleScale = parent.rippleScale;
			this.waveAmplitude = parent.waveAmplitude;
			this.animationSpeed = parent.animationSpeed;
		}
	}

	private static boolean equalsDefault(float value, float def) {
		return Math.abs(value - def) < 1.0e-6f;
	}

	/**
	 * Applies a quality-tier override on top of this material, returning a new
	 * instance (never mutates the registry entry). Missing fields fall through.
	 */
	public JellyMaterial withOverride(JellyMaterial override) {
		if (override == null) {
			return this;
		}
		JellyMaterial m = new JellyMaterial();
		m.id = this.id;
		m.parent = this.parent;
		m.baseColor = override.baseColor != null ? override.baseColor : this.baseColor;
		m.roughness = pick(override.roughness, this.roughness);
		m.metallic = pick(override.metallic, this.metallic);
		m.specular = pick(override.specular, this.specular);
		m.emissive = override.emissive != null ? override.emissive : this.emissive;
		m.emissiveStrength = pick(override.emissiveStrength, this.emissiveStrength);
		m.opacity = pick(override.opacity, this.opacity);
		m.transmission = pick(override.transmission, this.transmission);
		m.ior = pick(override.ior, this.ior);
		m.fresnelStrength = pick(override.fresnelStrength, this.fresnelStrength);
		m.subsurfaceStrength = pick(override.subsurfaceStrength, this.subsurfaceStrength);
		m.subsurfaceColor = override.subsurfaceColor != null ? override.subsurfaceColor : this.subsurfaceColor;
		m.thickness = pick(override.thickness, this.thickness);
		m.absorptionColor = override.absorptionColor != null ? override.absorptionColor : this.absorptionColor;
		m.absorptionDensity = pick(override.absorptionDensity, this.absorptionDensity);
		m.refractionStrength = pick(override.refractionStrength, this.refractionStrength);
		m.distortionStrength = pick(override.distortionStrength, this.distortionStrength);
		m.wetness = pick(override.wetness, this.wetness);
		m.clearcoat = pick(override.clearcoat, this.clearcoat);
		m.clearcoatRoughness = pick(override.clearcoatRoughness, this.clearcoatRoughness);
		m.reflectionIntensity = pick(override.reflectionIntensity, this.reflectionIntensity);
		m.normalStrength = pick(override.normalStrength, this.normalStrength);
		m.parallaxStrength = pick(override.parallaxStrength, this.parallaxStrength);
		m.animationSpeed = pick(override.animationSpeed, this.animationSpeed);
		m.rippleStrength = pick(override.rippleStrength, this.rippleStrength);
		m.rippleScale = pick(override.rippleScale, this.rippleScale);
		m.waveAmplitude = pick(override.waveAmplitude, this.waveAmplitude);
		m.edgeGlow = pick(override.edgeGlow, this.edgeGlow);
		m.depthFade = pick(override.depthFade, this.depthFade);
		m.sparkleStrength = pick(override.sparkleStrength, this.sparkleStrength);
		m.sparkleScale = pick(override.sparkleScale, this.sparkleScale);
		m.textureCrispness = pick(override.textureCrispness, this.textureCrispness);
		m.jellyStiffness = pick(override.jellyStiffness, this.jellyStiffness);
		m.jellyDamping = pick(override.jellyDamping, this.jellyDamping);
		m.jellyAmplitude = pick(override.jellyAmplitude, this.jellyAmplitude);
		return m;
	}

	private static float pick(float overrideValue, float baseValue) {
		// 0 in an override means "not specified" for nullable params where 0 is the default;
		// explicit zeroing is done by tiny nonzero sentinels or by providing the full set.
		return overrideValue != 0.0f ? overrideValue : baseValue;
	}
}
