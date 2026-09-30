#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_entities vertex
// Jelly jiggle for entities (small, world-space coherent, distance
// gated) driven by entityId material firmness.
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/materials.glsl"
#include "/lib/jelly.glsl"

uniform int entityId;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 viewNormal;
out vec3 viewPos;
out vec3 worldPos;
out float entId;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    entId = float(entityId);

    vec4 vp = gl_ModelViewMatrix * gl_Vertex;
    vec3 playerPos = (gbufferModelViewInverse * vp).xyz;
    vec3 wpos = playerPos + cameraPosition;

#if WOBBLE != 0 && VANILLA_MODE == 0
    JcMaterial m = jcEntityMaterial(entityId);
    if (m.jellyAmplitude > 0.0) {
        float amp = m.jellyAmplitude * (WOBBLE_STRENGTH * 0.01);
        float dist = length(playerPos);
        float gate = smoothstep(48.0, 32.0, dist);
        vec3 wNormal = mat3(gbufferModelViewInverse) * viewNormal;
        // gentle breathing/jiggle; hitbox stays believable (tiny amp)
        wpos += jcWobble(wpos, wNormal, amp * gate, 0.5, frameTimeCounter);
    }
#endif

    worldPos = wpos;
    playerPos = wpos - cameraPosition;
    vec4 viewPos4 = gbufferModelView * vec4(playerPos, 1.0);
    viewPos = viewPos4.xyz;
    gl_Position = gl_ProjectionMatrix * viewPos4;
}
