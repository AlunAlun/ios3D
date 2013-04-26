varying highp vec2 v_textureCoord;
uniform sampler2D u_textureSampler;
void main() {
   highp vec4 color1 = texture2D(u_textureSampler,v_textureCoord);
   gl_FragColor = color1;
}