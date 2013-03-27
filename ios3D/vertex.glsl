// Vertex Shader
 
uniform mediump mat4 ModelViewMatrix;
uniform mediump mat4 ProjectionMatrix;
uniform mediump mat3 NormalMatrix;
uniform mediump vec3 LightPosition;
 
attribute mediump vec3 VertexPosition;
attribute lowp vec3 VertexNormal;
attribute mediump vec2 VertexTexCoord0; /* new */
 
/* Varying means that it will be passed to the fragment shader after interpolation */
varying lowp vec3 LightColor;
varying mediump vec2 FragmentTexCoord0; /* new */
 
void main(void)
{
    /* Transform the vertex data in eye coordinates */
    mediump vec3 position = vec3(ModelViewMatrix * vec4(VertexPosition, 1.0));
    lowp vec3 normal = normalize(NormalMatrix * VertexNormal);
    
    /* Calculate the light direction */
    mediump vec3 lightdirection = normalize(LightPosition - position);
    
    /* Calculate the intensity of the light with the dot product */
    lowp float ndotl = max(dot(normal, lightdirection), 0.0);
    
    /* Light color = intensity * color of the light */
    LightColor = ndotl * vec3(1.0);
    FragmentTexCoord0 = VertexTexCoord0; /* new */
    
    /* Transform the positions from eye coordinates to clip coordinates */
    gl_Position = ProjectionMatrix * vec4(position, 1.0);
}
