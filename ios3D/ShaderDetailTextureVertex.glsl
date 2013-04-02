// Vertex Shader
 
uniform mediump mat4 ModelViewMatrix;
uniform mediump mat4 ProjectionMatrix;
uniform mediump mat3 NormalMatrix;
uniform mediump vec3 LightPosition;
 
attribute mediump vec3 VertexPosition;
attribute mediump vec3 VertexNormal;
attribute mediump vec2 VertexTexCoord0;

 
/* Varying means that it will be passed to the fragment shader after interpolation */
//varying mediump vec3 DiffuseColor;
varying mediump vec3 E;
varying mediump vec3 LD;
varying mediump vec3 N;
varying mediump vec3 R;
varying mediump vec2 FragmentTexCoord0; 
 
void main(void)
{
    /* Transform the vertex data in eye coordinates */
    mediump vec3 position = vec3(ModelViewMatrix * vec4(VertexPosition, 1.0));
    N = normalize(NormalMatrix * VertexNormal);
    
    /* Calculate the light direction */
    LD = normalize(LightPosition - position);
    E = normalize(-position);
    R = reflect(-LD, N);
    
    FragmentTexCoord0 = VertexTexCoord0; 
    
    /* Transform the positions from eye coordinates to clip coordinates */
    gl_Position = ProjectionMatrix * vec4(position, 1.0);
}
