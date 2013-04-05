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
attribute mediump vec2 a_vertexTexCoord0;

varying mediump vec3 v_light_dir;
varying mediump vec3 v_normal;
varying mediump vec3 v_pos;
varying mediump vec2 v_fragmentTexCoord0;

void main(void)
{
    /* world space lighting */
    v_pos = (u_m * vec4(a_vertex,1.0)).xyz;
    v_normal = u_normal_model * a_normal;
    
    /* Transform the vertex data in eye coordinates */
    mediump mat4 tmp_mv = u_v * u_m;
    mediump vec3 position = vec3(tmp_mv * vec4(a_vertex, 1.0));
    
    /*pass the texture coordinate onto the fragment shader */
    v_fragmentTexCoord0 = a_vertexTexCoord0;
    
    /* Transform the positions from eye coordinates to clip coordinates */
    gl_Position = u_p * vec4(position, 1.0);
}

/*

// Vertex Shader
 
uniform mediump mat4 ModelViewMatrix;
uniform mediump mat4 ProjectionMatrix;
uniform mediump mat3 NormalMatrix;
uniform mediump vec3 LightPosition;
 
attribute mediump vec3 VertexPosition;
attribute mediump vec3 VertexNormal;
attribute mediump vec2 VertexTexCoord0;

 
/* Varying means that it will be passed to the fragment shader after interpolation *
//varying mediump vec3 DiffuseColor;
varying mediump vec3 E;
varying mediump vec3 LD;
varying mediump vec3 N;
varying mediump vec3 R;
varying mediump vec2 FragmentTexCoord0; 
 
void main(void)
{
    /* Transform the vertex data in eye coordinates *
    mediump vec3 position = vec3(ModelViewMatrix * vec4(VertexPosition, 1.0));
    N = normalize(NormalMatrix * VertexNormal);
    
    /* Calculate the light direction *
    LD = normalize(LightPosition - position);
    E = normalize(-position);
    R = reflect(-LD, N);
    
    FragmentTexCoord0 = VertexTexCoord0; 
    
    /* Transform the positions from eye coordinates to clip coordinates *
    gl_Position = ProjectionMatrix * vec4(position, 1.0);
}
 */
