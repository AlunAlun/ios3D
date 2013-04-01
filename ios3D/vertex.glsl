// Vertex Shader
 
uniform lowp mat4 ModelViewMatrix;
uniform lowp mat4 ProjectionMatrix;
uniform lowp mat3 NormalMatrix;
uniform lowp vec3 LightPosition;
 
attribute lowp vec3 VertexPosition;
attribute lowp vec3 VertexNormal;
attribute lowp vec2 VertexTexCoord0; 
 
/* Varying means that it will be passed to the fragment shader after interpolation */
//varying lowp vec3 DiffuseColor;
varying lowp vec3 EyeVec;
varying lowp vec3 LightDirection;
varying lowp vec3 Normal;
varying lowp vec2 FragmentTexCoord0; 
 
void main(void)
{
    /* Transform the vertex data in eye coordinates */
    lowp vec3 position = vec3(ModelViewMatrix * vec4(VertexPosition, 1.0));
    Normal = NormalMatrix * VertexNormal;
    
    /* Calculate the light direction */
    LightDirection = LightPosition - position;
    EyeVec = -position;
    
    FragmentTexCoord0 = VertexTexCoord0; 
    
    /* Transform the positions from eye coordinates to clip coordinates */
    gl_Position = ProjectionMatrix * vec4(position, 1.0);
}
