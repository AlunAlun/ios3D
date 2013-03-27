// Fragment shader

uniform sampler2D TextureSampler; 

varying lowp vec3 LightColor;
varying mediump vec2 FragmentTexCoord0;
 
void main(void)
{
    /* Add diffuse and ambient light (constant) */
    gl_FragColor = texture2D(TextureSampler, FragmentTexCoord0) * vec4(LightColor, 1.0) + vec4(0.1);
}