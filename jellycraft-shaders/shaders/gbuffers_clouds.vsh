#version 330 compatibility
// JELLYCRAFT — gbuffers_clouds vertex
#include "/lib/settings.glsl"

out vec2 texcoord;
out vec4 glcolor;
out vec3 viewNormal;
out vec3 viewPos;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vec4 vp = gl_ModelViewMatrix * gl_Vertex;
    viewPos = vp.xyz;
    gl_Position = gl_ProjectionMatrix * vp;
}
