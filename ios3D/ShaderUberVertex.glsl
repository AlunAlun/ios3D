

// Vertex Shader
precision highp float;

uniform highp mat4 u_m;
uniform highp mat4 u_v;
uniform highp mat4 u_mv;
uniform highp mat4 u_p;
uniform highp mat3 u_normal;
uniform highp mat3 u_normal_model;

 
attribute highp vec3 a_vertex;
attribute highp vec3 a_normal;

varying highp vec3 v_light_dir;
varying highp vec3 v_normal;
varying highp vec3 v_pos;

#if defined (USE_DIFFUSE_TEXTURE) | defined (USE_DETAIL_TEXTURE)
attribute mediump vec2 a_vertexTexCoord0;
varying mediump vec2 v_fragmentTexCoord0;
#endif

void main(void)
{
    /* world space lighting */
    v_pos = (u_m * vec4(a_vertex,1.0)).xyz;
    v_normal = u_normal_model * a_normal;
    
    /* Transform the vertex data in eye coordinates */
    highp mat4 tmp_mv = u_v * u_m;
    highp vec3 position = vec3(u_mv * vec4(a_vertex, 1.0));

    /* Transform the positions from eye coordinates to clip coordinates */
    gl_Position = u_p * vec4(position, 1.0);
    
#ifdef USE_DIFFUSE_TEXTURE
    v_fragmentTexCoord0 = a_vertexTexCoord0;
#endif
}
