#version 330 compatibility
// ================================================================
// JELLYCRAFT — shadow vertex
// Translucent gel blocks (water/ice/lava/glass) are pushed off-
// screen so the jelly liquid never casts a hard shadow.
// ================================================================

#include "/lib/settings.glsl"

in vec4 mc_Entity;

out vec2 texcoord;
out vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    int id = int(mc_Entity.x + 0.5);
    if (id == 10007 || id == 10008 || id == 10009 || id == 10010) {
        gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);   // cull from shadow map
        return;
    }
    gl_Position = ftransform();
}
