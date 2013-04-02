// Fragment shader

uniform sampler2D TextureSampler;
uniform sampler2D DetailSampler;
uniform bool UseDetail;

uniform mediump vec4 matDiffuse;
uniform mediump vec4 matAmbient;
uniform mediump vec4 matSpecular;
uniform mediump float matShininess;

//uniform mediump vec4 LightColor;
uniform mediump float LightIntensity;

varying mediump vec3 E; // Eye Vector, already normalized
varying mediump vec3 LD; // Light Direction, already normalized
varying mediump vec3 N; // Normal, already normalized
varying mediump vec3 R; // reflect component
varying mediump vec2 FragmentTexCoord0;
 
void main(void)
{
    
    // diffuse
    mediump float ndotl = max(dot(N, LD), 0.0);
    mediump vec3 DiffuseColor = ndotl * vec3(1.0);
    mediump vec4 diffuseTotal = vec4(DiffuseColor, 1.0) * matDiffuse * LightIntensity;

    // specular

	mediump float specFloat = pow( max(dot(R, E), 0.0), matShininess );
    mediump vec4 specVec = matSpecular * specFloat;
   
    //texture + phong
    mediump vec4 finalColor = texture2D(TextureSampler, FragmentTexCoord0) * (diffuseTotal + matAmbient + specVec) ;

    /* Add detail texture */
    if (UseDetail)
    {
        mediump vec2 FragmentTexCoord1 = FragmentTexCoord0*6.0;
        finalColor += (texture2D(DetailSampler, FragmentTexCoord1)-vec4(0.5))*0.3;
    }

    gl_FragColor = finalColor ;

}