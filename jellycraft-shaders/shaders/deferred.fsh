#version 330 compatibility
// ================================================================
// JELLYCRAFT — deferred fragment
// Runs after opaque geometry, BEFORE translucents: snapshots the
// opaque scene into colortex3. This is the refraction source for
// the jelly liquid, glass blocks and the glass pickaxe, and the
// depth-valid refraction reference (never contains the gel itself,
// so nothing can smear onto itself).
// ================================================================

/* RENDERTARGETS: 3 */
layout(location = 0) out vec4 fragColor;

uniform sampler2D colortex0;

in vec2 texcoord;

void main() {
    fragColor = texture(colortex0, texcoord);
}
