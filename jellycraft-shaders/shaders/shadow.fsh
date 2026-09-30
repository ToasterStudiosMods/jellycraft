#version 330 compatibility
// JELLYCRAFT — shadow fragment (cutout-aware depth shadow)

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    if (tex.a < 0.35) discard;    // leaves & cutouts keep dappled shadows
    fragColor = vec4(tex.rgb, 1.0);
}
