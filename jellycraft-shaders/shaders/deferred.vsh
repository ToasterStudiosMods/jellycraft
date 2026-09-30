#version 330 compatibility
// JELLYCRAFT — deferred vertex (fullscreen quad)
out vec2 texcoord;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    gl_Position = ftransform();
}
