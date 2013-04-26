attribute highp vec3 a_vertex;

uniform mat4 u_depthMVP;

varying highp vec3 v_pos;

void main(){
    highp vec4 v_pos4 = u_depthMVP * vec4(a_vertex,1.0);
    v_pos = v_pos4.xyz
    gl_Position = v_pos4;
}