#version 330 compatibility
// JELLYCRAFT — gbuffers_skybasic vertex (sky disc, horizon band, stars, void)
out vec4 glcolor;

void main() {
    glcolor = gl_Color;
    gl_Position = ftransform();
}
