#version 330 compatibility
// JELLYCRAFT — gbuffers_block vertex (block entities: chests etc.)
out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 viewNormal;
out vec3 viewPos;
out vec3 worldPos;

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    vec4 vp = gl_ModelViewMatrix * gl_Vertex;
    viewPos = vp.xyz;
    worldPos = (gbufferModelViewInverse * vp).xyz + cameraPosition;
    gl_Position = gl_ProjectionMatrix * vp;
}
