// Vertex Shader
precision highp float;

uniform mediump mat4 u_m;
uniform mediump mat4 u_v;
uniform mediump mat4 u_mv;
uniform mediump mat4 u_p;
uniform mediump mat3 u_normal;
uniform mediump mat3 u_normal_model;

 
attribute mediump vec3 a_vertex;
attribute mediump vec3 a_normal;

varying mediump vec3 v_light_dir;
varying mediump vec3 v_normal;
varying mediump vec3 v_pos;

void main(void)
{
    /* world space lighting */
    v_pos = (u_m * vec4(a_vertex,1.0)).xyz;
    v_normal = u_normal_model * a_normal;
    
    /* Transform the vertex data in eye coordinates */
    mediump mat4 tmp_mv = u_v * u_m;
    mediump vec3 position = vec3(tmp_mv * vec4(a_vertex, 1.0));

    /* Transform the positions from eye coordinates to clip coordinates */
    gl_Position = u_p * vec4(position, 1.0);
}
