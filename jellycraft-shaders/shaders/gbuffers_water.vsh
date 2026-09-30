#version 330 compatibility
// ================================================================
// JELLYCRAFT — gbuffers_water vertex
// Translucent terrain: jelly liquid (10007), ice (10008), lava
// (10009), glass (10010). Liquid gets a small continuous world-
// space surface wave (voxel-safe amplitude) + soft wobble.
// ================================================================

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/materials.glsl"
#include "/lib/jelly.glsl"

in vec4 mc_Entity;

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
out float matId;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;
    viewNormal = normalize(gl_NormalMatrix * gl_Normal);
    matId = mc_Entity.x;

    vec4 vp = gl_ModelViewMatrix * gl_Vertex;
    vec3 playerPos = (gbufferModelViewInverse * vp).xyz;
    vec3 wpos = playerPos + cameraPosition;

#if WOBBLE != 0 && VANILLA_MODE == 0
    JcMaterial m = jcMaterialById(matId);
    if (m.jellyAmplitude > 0.0) {
        float amp = m.jellyAmplitude * (WOBBLE_STRENGTH * 0.01);
        float dist = length(playerPos);
        float gate = smoothstep(64.0, 40.0, dist);
        // liquid wave: vertical swell only, continuous in world space
        if (m.waveAmplitude > 0.0) {
            float wave = sin(wpos.x * 0.9 + frameTimeCounter * 1.6)
                       + sin(wpos.z * 0.7 + frameTimeCounter * 1.3);
            wpos.y += m.waveAmplitude * (WOBBLE_STRENGTH * 0.01) * gate * wave * 0.35;
        }
        vec3 wNormal = mat3(gbufferModelViewInverse) * viewNormal;
        wpos += jcWobble(wpos, wNormal, amp * gate * 0.6, m.rippleStrength > 0.0 ? 0.25 : 0.85,
                         frameTimeCounter);
    }
#endif

#if PLAYER_BEND != 0 && VANILLA_MODE == 0
    // Use the identical position-only field as solid terrain to keep the
    // shoreline continuous while gel water yields around the player.
    wpos += jcPlayerBend(playerPos, frameTimeCounter, PLAYER_BEND_STRENGTH * 0.01);
#endif

    worldPos = wpos;
    playerPos = wpos - cameraPosition;
    vec4 viewPos4 = gbufferModelView * vec4(playerPos, 1.0);
    viewPos = viewPos4.xyz;
    gl_Position = gl_ProjectionMatrix * viewPos4;
}
