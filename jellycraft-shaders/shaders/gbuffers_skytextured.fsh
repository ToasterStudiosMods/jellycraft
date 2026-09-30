#version 330 compatibility
// JELLYCRAFT — gbuffers_skytextured fragment (sun/moon)
// Sun pushed toward hot white (bloom catches it); moon kept soft.

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

void main() {
    vec4 tex = texture(gtexture, texcoord) * glcolor;
    vec3 color = tex.rgb;
#if VANILLA_MODE == 0
    float lum = jcLuminance(color);
    if (lum > 0.5) {
        // sun: hot white core (HDR headroom → bloom in final)
        color = mix(color, vec3(1.6, 1.45, 1.15), 0.55);
    }
#endif
    fragColor = vec4(color, tex.a);
}
