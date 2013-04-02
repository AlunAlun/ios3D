// Fragment shader

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
 
void main(void)
{
    
    // diffuse
    mediump float ndotl = max(dot(N, LD), 0.0);
    mediump vec3 DiffuseColor = ndotl * vec3(1.0);
    mediump vec4 diffuseTotal = vec4(DiffuseColor, 1.0) * matDiffuse * LightIntensity;

    // specular

	mediump float specFloat = pow( max(dot(R, E), 0.0), matShininess );
    mediump vec4 specVec = matSpecular * specFloat;
   

    gl_FragColor = (diffuseTotal + matAmbient + specVec) ;

}