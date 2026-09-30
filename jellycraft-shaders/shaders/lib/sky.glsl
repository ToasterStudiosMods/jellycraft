// ================================================================
// JELLYCRAFT — sky gradient (Section 11)
// Requires: /lib/common.glsl included first.
// ================================================================

vec3 jcSkyColor(vec3 dirWorld, vec3 skyColor, vec3 fogColor) {
    float h = clamp(dirWorld.y, -1.0, 1.0);
    vec3 zenith = jcSaturation(skyColor * 1.06, 1.12);
    vec3 horizon = mix(fogColor, skyColor, 0.40) * 1.02;
    float t = pow(clamp(h, 0.0, 1.0), 0.55);
    vec3 sky = mix(horizon, zenith, t);
    // below-horizon fade toward a deeper tone (void plane)
    sky = mix(sky, skyColor * 0.55, smoothstep(0.0, -0.35, h));
    return sky;
}
